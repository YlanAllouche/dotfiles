from __future__ import annotations

import copy
import os
import re
from collections.abc import Mapping

from ansible.errors import AnsibleError, AnsibleParserError
from ansible.plugins.loader import lookup_loader
from ansible.plugins.vars import BaseVarsPlugin
from ansible.utils.path import basedir


_MISSING = object()
_ENV_KEY_RE = re.compile(r'[^A-Za-z0-9]+')
_CONFIG_CACHE = {}
_BUILTIN_CONTRACTS = {
    'email_account': {
        'address': 'address',
        'realname': {
            'required': False,
        },
        'maildir': {
            'required': False,
        },
        'sync.imap.host': 'imap_host',
        'sync.imap.port': {
            'field': 'imap_port',
            'cast': 'int',
        },
        'sync.imap.user': 'imap_user',
        'sync.imap.password': 'imap_password',
        'sync.imap.auth_mechs': {
            'field': 'imap_auth_mechs',
            'default': 'LOGIN',
        },
        'sync.imap.ssl_type': {
            'field': 'imap_ssl_type',
            'default': 'IMAPS',
        },
        'send.smtp.host': 'smtp_host',
        'send.smtp.port': {
            'field': 'smtp_port',
            'cast': 'int',
        },
        'send.smtp.user': 'smtp_user',
        'send.smtp.password': 'smtp_password',
        'send.smtp.tls_starttls': {
            'field': 'smtp_tls_starttls',
            'cast': 'bool',
            'default': False,
        },
    },
}


class VarsModule(BaseVarsPlugin):
    REQUIRES_ENABLED = True
    is_stateless = True

    def get_vars(self, loader, path, entities, cache=True):
        data = {}
        for config_path in self._candidate_config_paths(loader, path):
            config_data = self._load_config(loader, config_path, cache=cache)
            if config_data is None:
                continue
            try:
                resolved = self._resolve_config(config_data, loader, config_path)
            except AnsibleError as exc:
                raise AnsibleParserError(f'Unable to resolve Bitwarden consumer config `{config_path}`.') from exc
            data.update(resolved)
            break
        return data

    def _candidate_config_paths(self, loader, path):
        candidates = []
        seen = set()
        for base in (loader.get_basedir(), basedir(path)):
            if not base:
                continue
            config_path = os.path.realpath(os.path.join(base, 'vars', 'bitwarden.yml'))
            if config_path in seen:
                continue
            seen.add(config_path)
            candidates.append(config_path)
        return candidates

    def _load_config(self, loader, config_path, cache=True):
        if cache and config_path in _CONFIG_CACHE:
            return copy.deepcopy(_CONFIG_CACHE[config_path])

        if not os.path.exists(config_path):
            return None

        data = loader.load_from_file(config_path, cache='all', unsafe=True, trusted_as_template=True)
        if not data:
            data = {}
        if not isinstance(data, Mapping):
            raise AnsibleParserError(f'Bitwarden consumer config `{config_path}` must contain a YAML mapping.')

        if cache:
            _CONFIG_CACHE[config_path] = copy.deepcopy(data)
        return data

    def _resolve_config(self, data, loader, config_path):
        if 'bitwarden' not in data:
            raise AnsibleError(f'Bitwarden consumer config `{config_path}` must define a top-level `bitwarden:` mapping.')

        config = data['bitwarden']
        if not isinstance(config, Mapping):
            raise AnsibleError(f'Bitwarden consumer config `{config_path}` must define `bitwarden` as a mapping.')

        bindings = config.get('bindings', {}) or {}
        values = config.get('values', {}) or {}
        objects = config.get('objects', {}) or {}
        contract_definitions = config.get('contract_definitions', {}) or {}
        contract_overrides = config.get('contract_overrides', {}) or {}
        role_exports = config.get('role_exports', {}) or {}

        self._ensure_mapping(bindings, 'bitwarden.bindings')
        self._ensure_mapping(values, 'bitwarden.values')
        self._ensure_mapping(objects, 'bitwarden.objects')
        self._ensure_mapping(contract_definitions, 'bitwarden.contract_definitions')
        self._ensure_mapping(contract_overrides, 'bitwarden.contract_overrides')
        self._ensure_mapping(role_exports, 'bitwarden.role_exports')

        bw_item_lookup = self._load_bw_item_lookup(loader)
        base_dir = os.path.dirname(os.path.dirname(config_path))

        resolved_bindings = {
            name: self._resolve_binding(name, binding, bw_item_lookup, loader, base_dir)
            for name, binding in bindings.items()
        }
        resolved_values = {
            name: self._resolve_value_output(name, value_config, resolved_bindings)
            for name, value_config in values.items()
        }
        resolved_objects = {
            name: self._resolve_object_output(name, object_config, resolved_bindings)
            for name, object_config in objects.items()
        }

        resolved_contracts = {}
        contract_names_by_binding = {}
        for name, binding in bindings.items():
            contract_name = self._binding_contract_name(name, binding)
            if not contract_name:
                continue
            spec = self._resolve_contract_spec(
                contract_name,
                contract_definitions,
                contract_overrides,
                binding.get('overrides', {}),
            )
            defaults = self._contract_defaults_for_binding(name, binding, base_dir)
            resolved_contracts[name] = self._apply_contract(
                resolved_bindings[name],
                spec,
                defaults=defaults,
                context_prefix=f'bitwarden.bindings.{name}',
            )
            contract_names_by_binding[name] = contract_name

        resolved_role_exports = {
            name: self._resolve_role_export(
                name,
                export_config,
                resolved_contracts,
                contract_names_by_binding,
            )
            for name, export_config in role_exports.items()
        }

        resolved = {
            'bindings': resolved_bindings,
            'values': resolved_values,
            'objects': resolved_objects,
            'contracts': resolved_contracts,
            'role_exports': resolved_role_exports,
        }

        output = {'bitwarden': copy.deepcopy(config), 'bitwarden_resolved': resolved}
        self._publish_output_vars(output, resolved_values, 'bitwarden.values')
        self._publish_output_vars(output, resolved_objects, 'bitwarden.objects')
        self._publish_output_vars(output, resolved_contracts, 'bitwarden.bindings contracts')

        for export_name, export_values in resolved_role_exports.items():
            self._publish_output_vars(output, export_values, f'bitwarden.role_exports.{export_name}')

        return output

    def _ensure_mapping(self, value, label):
        if not isinstance(value, Mapping):
            raise AnsibleError(f'`{label}` must be a mapping.')

    def _publish_output_vars(self, output, new_values, label):
        for key, value in new_values.items():
            if key in output:
                raise AnsibleError(f'Bitwarden export collision for `{key}` while publishing `{label}`.')
            output[key] = value

    def _load_bw_item_lookup(self, loader):
        plugin = lookup_loader.get('bw_item', loader=loader, templar=None)
        if plugin is None:
            raise AnsibleError('Unable to load the local `bw_item` lookup plugin.')
        return plugin

    def _resolve_binding(self, name, config, bw_item_lookup, loader, base_dir):
        if isinstance(config, str):
            binding = {'item': config}
        elif isinstance(config, Mapping):
            binding = dict(config)
        else:
            raise AnsibleError(f'`bitwarden.bindings.{name}` must be a string item name or a mapping.')

        item_term = binding.get('item') or binding.get('name')
        if item_term is None:
            raise AnsibleError(f'`bitwarden.bindings.{name}` must define `item`.')

        if isinstance(item_term, Mapping):
            return item_term

        if not isinstance(item_term, str) or not item_term:
            raise AnsibleError(f'`bitwarden.bindings.{name}.item` must be a non-empty string or an inline item mapping.')

        lookup_kwargs = {}
        for key in ('collection_name', 'bw_session', 'required', 'default'):
            if key in binding:
                lookup_kwargs[key] = binding[key]

        items = bw_item_lookup.run([item_term], variables={'playbook_dir': base_dir}, **lookup_kwargs)
        if not items:
            return None
        return items[0]

    def _resolve_value_output(self, name, config, resolved_bindings):
        if isinstance(config, str):
            value_config = {'binding': config}
        elif isinstance(config, Mapping):
            value_config = dict(config)
        else:
            raise AnsibleError(f'`bitwarden.values.{name}` must be a string binding name or a mapping.')

        binding_name = value_config.get('binding', name)
        item = self._get_binding_item(binding_name, resolved_bindings, f'bitwarden.values.{name}')
        value = self._resolve_item_value(
            item,
            field=value_config.get('field', 'password'),
            required=value_config.get('required'),
            default_provided='default' in value_config,
            default_value=value_config.get('default'),
            cast=value_config.get('cast'),
            context=f'bitwarden.values.{name}',
        )
        return None if value is _MISSING else value

    def _resolve_object_output(self, name, config, resolved_bindings):
        if isinstance(config, str):
            object_config = {'binding': config}
        elif isinstance(config, Mapping):
            object_config = dict(config)
        else:
            raise AnsibleError(f'`bitwarden.objects.{name}` must be a string binding name or a mapping.')

        binding_name = object_config.get('binding', name)
        item = self._get_binding_item(binding_name, resolved_bindings, f'bitwarden.objects.{name}')
        style = object_config.get('style', 'plain')
        include_login = object_config.get('include_login', True)

        if style in ('fields', 'raw'):
            return self._bw_fields(item, include_login=include_login)

        prefix = object_config.get('prefix', binding_name)
        return self._bw_prefixed(item, prefix=prefix, style=style, include_login=include_login)

    def _binding_contract_name(self, name, binding):
        if not isinstance(binding, Mapping):
            return None
        return binding.get('contract')

    def _resolve_contract_spec(self, contract_name, contract_definitions, contract_overrides, binding_overrides):
        if contract_name in _BUILTIN_CONTRACTS:
            spec = self._normalize_contract_spec_map(_BUILTIN_CONTRACTS[contract_name])
        elif contract_name in contract_definitions:
            spec = self._normalize_contract_spec_map(contract_definitions[contract_name])
        else:
            raise AnsibleError(f'Unknown Bitwarden contract `{contract_name}`.')

        if contract_name in contract_overrides:
            spec = self._merge_contract_specs(spec, contract_overrides[contract_name])

        if binding_overrides:
            spec = self._merge_contract_specs(spec, binding_overrides)

        return spec

    def _contract_defaults_for_binding(self, name, binding, base_dir):
        contract_name = self._binding_contract_name(name, binding)
        defaults = copy.deepcopy(binding.get('defaults', {})) if isinstance(binding, Mapping) else {}
        if not contract_name:
            return defaults

        if contract_name != 'email_account':
            return defaults

        account_id = self._infer_mail_account_id(name, binding)
        maildir = binding.get('maildir', defaults.get('maildir', account_id))
        signature_src = binding.get('signature_src', defaults.get('signature_src', _MISSING))
        if signature_src is _MISSING:
            inferred_signature = os.path.join(base_dir, 'files', 'mail', 'accounts', account_id, 'signature')
            signature_src = inferred_signature if os.path.exists(inferred_signature) else _MISSING

        base_defaults = {
            'id': account_id,
            'enabled': binding.get('enabled', True),
            'primary': binding.get('primary', False),
            'maildir': maildir,
            'sync': {
                'backend': 'mbsync',
                'enabled': True,
                'folders': ['INBOX', '*'],
                'create': 'Both',
                'sync_mode': 'All',
                'subfolders': 'Legacy',
            },
            'send': {
                'enabled': True,
            },
        }
        if signature_src is not _MISSING:
            base_defaults['signature_src'] = signature_src

        return self._deep_merge(base_defaults, defaults)

    def _infer_mail_account_id(self, name, binding):
        if isinstance(binding, Mapping) and binding.get('id'):
            return binding['id']
        if name.startswith('mail_') and len(name) > 5:
            return name[5:]
        return name

    def _resolve_role_export(self, name, config, resolved_contracts, contract_names_by_binding):
        if not isinstance(config, Mapping):
            raise AnsibleError(f'`bitwarden.role_exports.{name}` must be a mapping.')

        if name != 'email':
            raise AnsibleError(f'Unsupported Bitwarden role export `{name}`. Only `email` is currently built in.')

        contract_name = config.get('contract')
        if not contract_name:
            raise AnsibleError('`bitwarden.role_exports.email.contract` must be defined.')

        selected_bindings = [
            binding_name
            for binding_name, resolved_contract_name in contract_names_by_binding.items()
            if resolved_contract_name == contract_name
        ]
        if not selected_bindings:
            raise AnsibleError(
                f'`bitwarden.role_exports.email.contract` did not match any resolved bindings for contract `{contract_name}`.'
            )

        primary_binding = config.get('primary', '')
        email_accounts = []
        for binding_name in selected_bindings:
            account = copy.deepcopy(resolved_contracts[binding_name])
            if primary_binding:
                is_primary = binding_name == primary_binding
                account['primary'] = is_primary
                resolved_contracts[binding_name]['primary'] = is_primary
            email_accounts.append(account)

        if primary_binding:
            if primary_binding not in resolved_contracts:
                raise AnsibleError(
                    f'`bitwarden.role_exports.email.primary` references unknown contract binding `{primary_binding}`.'
                )
            primary_id = resolved_contracts[primary_binding].get('id', '')
        else:
            primary_id = next((account.get('id', '') for account in email_accounts if account.get('primary')), '')

        return {
            'email_accounts': email_accounts,
            'email_primary_account_id': primary_id,
        }

    def _get_binding_item(self, binding_name, resolved_bindings, context):
        if binding_name not in resolved_bindings:
            raise AnsibleError(f'`{context}` references unknown binding `{binding_name}`.')
        return resolved_bindings[binding_name]

    def _custom_fields(self, item):
        fields = {}
        for field in item.get('fields', []) or []:
            if not isinstance(field, Mapping):
                continue
            name = field.get('name')
            if name:
                fields[name] = field.get('value')
        return fields

    def _bw_fields(self, item, include_login=False):
        item = self._ensure_item(item)
        fields = self._custom_fields(item)
        if include_login:
            login = item.get('login') or {}
            if 'username' in login:
                fields.setdefault('username', login.get('username'))
            if 'password' in login:
                fields.setdefault('password', login.get('password'))
        return fields

    def _bw_prefixed(self, item, prefix, style='plain', include_login=True):
        if not prefix:
            raise AnsibleError('`bw_prefixed` requires a non-empty `prefix`.')

        fields = self._bw_fields(item, include_login=include_login)
        if style == 'plain':
            return {f'{prefix}_{key}': value for key, value in fields.items()}
        if style == 'env':
            env_prefix = self._sanitize_env_key(str(prefix))
            return {f'{env_prefix}_{self._sanitize_env_key(key)}': value for key, value in fields.items()}

        raise AnsibleError('Bitwarden object styles support only `fields`, `plain`, and `env`.')

    def _sanitize_env_key(self, value):
        normalized = _ENV_KEY_RE.sub('_', value).strip('_')
        return normalized.upper()

    def _ensure_item(self, item):
        if not isinstance(item, Mapping):
            raise AnsibleError('Bitwarden helpers expect a Bitwarden item object (a mapping).')
        return item

    def _cast_value(self, value, cast):
        if cast in (None, '', 'raw'):
            return value
        if cast == 'str':
            return str(value)
        if cast == 'int':
            return int(value)
        if cast == 'float':
            return float(value)
        if cast == 'bool':
            if isinstance(value, bool):
                return value
            normalized = str(value).strip().lower()
            if normalized in {'1', 'true', 'yes', 'on'}:
                return True
            if normalized in {'0', 'false', 'no', 'off'}:
                return False
            raise AnsibleError(f'Cannot cast value `{value}` to bool.')
        raise AnsibleError(f'Unsupported cast `{cast}`. Expected one of: str, int, float, bool, raw.')

    def _resolve_item_value(self, item, *, field, required, default_provided, default_value, cast, context):
        if required is None:
            required = not default_provided

        if item is None:
            if default_provided:
                return self._cast_value(default_value, cast)
            if required:
                raise AnsibleError(f'`{context}` references a Bitwarden item that could not be resolved.')
            return _MISSING

        field_name = field or 'password'
        login = item.get('login') or {}

        if field_name == 'password':
            value = login.get('password', _MISSING)
        elif field_name == 'username':
            value = login.get('username', _MISSING)
        else:
            value = self._custom_fields(item).get(field_name, _MISSING)

        if value is _MISSING:
            if default_provided:
                return self._cast_value(default_value, cast)
            if required:
                raise AnsibleError(f'`{context}` is missing required field `{field_name}`.')
            return _MISSING

        return self._cast_value(value, cast)

    def _normalize_contract_spec_map(self, raw_spec):
        if not isinstance(raw_spec, Mapping):
            raise AnsibleError('Bitwarden contract definitions must be mappings keyed by destination paths.')

        return {
            destination: self._normalize_contract_entry(destination, config)
            for destination, config in raw_spec.items()
        }

    def _normalize_contract_entry(self, destination, config):
        if isinstance(config, str):
            return {
                'destination': destination,
                'field': config,
                'required': True,
            }

        if not isinstance(config, Mapping):
            raise AnsibleError(
                f'Bitwarden contract destination `{destination}` must be a string field name or a mapping of options.'
            )

        spec = dict(config)
        spec.setdefault('destination', destination)
        spec.setdefault('field', destination.rsplit('.', 1)[-1])
        if 'required' not in spec:
            spec['required'] = 'default' not in spec
        return spec

    def _merge_contract_specs(self, base_spec, overrides):
        self._ensure_mapping(overrides, 'contract override')
        result = copy.deepcopy(base_spec)
        normalized_overrides = self._normalize_contract_spec_map(overrides)

        for destination, override_spec in normalized_overrides.items():
            merged = dict(result.get(destination, {'destination': destination, 'field': destination.rsplit('.', 1)[-1]}))
            merged.update(override_spec)
            result[destination] = merged

        return result

    def _apply_contract(self, item, spec, defaults=None, context_prefix='Bitwarden contract'):
        item = self._ensure_item(item)
        result = copy.deepcopy(defaults) if defaults is not None else {}
        if not isinstance(result, Mapping):
            raise AnsibleError(f'`{context_prefix}` defaults must be a mapping when provided.')

        result = dict(result)
        for destination, field_spec in spec.items():
            default_provided = 'default' in field_spec
            value = self._resolve_item_value(
                item,
                field=field_spec['field'],
                required=field_spec['required'],
                default_provided=default_provided,
                default_value=field_spec.get('default'),
                cast=field_spec.get('cast'),
                context=f'{context_prefix} destination `{destination}`',
            )
            if value is _MISSING:
                continue
            self._set_path(result, field_spec['destination'], value)

        return result

    def _set_path(self, target, destination, value):
        cursor = target
        parts = destination.split('.')
        for part in parts[:-1]:
            existing = cursor.get(part)
            if existing is None:
                cursor[part] = {}
                existing = cursor[part]
            elif not isinstance(existing, Mapping):
                raise AnsibleError(
                    f'Cannot assign `{destination}` because `{part}` already contains a non-mapping value.'
                )
            cursor = existing
        cursor[parts[-1]] = value

    def _deep_merge(self, base, override):
        result = copy.deepcopy(base)
        for key, value in override.items():
            if key in result and isinstance(result[key], Mapping) and isinstance(value, Mapping):
                result[key] = self._deep_merge(result[key], value)
            else:
                result[key] = copy.deepcopy(value)
        return result
