from __future__ import annotations

import copy
import re
from collections.abc import Mapping

from ansible.errors import AnsibleFilterError


_MISSING = object()
_ENV_KEY_RE = re.compile(r'[^A-Za-z0-9]+')


def _ensure_item(item):
    if not isinstance(item, Mapping):
        raise AnsibleFilterError('Bitwarden filters expect a Bitwarden item object (a mapping).')
    return item


def _custom_fields(item):
    fields = {}
    for field in item.get('fields', []) or []:
        if not isinstance(field, Mapping):
            continue
        name = field.get('name')
        if name:
            fields[name] = field.get('value')
    return fields


def _cast_value(value, cast):
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
        raise AnsibleFilterError(f'Cannot cast value `{value}` to bool.')
    raise AnsibleFilterError(f'Unsupported cast `{cast}`. Expected one of: str, int, float, bool, raw.')


def _resolve_value(item, *, field, required, default_provided, default_value, cast, context):
    item = _ensure_item(item)
    field_name = field or 'password'
    login = item.get('login') or {}

    if field_name == 'password':
        value = login.get('password', _MISSING)
    elif field_name == 'username':
        value = login.get('username', _MISSING)
    else:
        value = _custom_fields(item).get(field_name, _MISSING)

    if value is _MISSING:
        if default_provided:
            return _cast_value(default_value, cast)
        if required:
            item_name = item.get('name', '<inline item>')
            raise AnsibleFilterError(f'{context or f"Bitwarden item `{item_name}`"} is missing required field `{field_name}`.')
        return _MISSING

    return _cast_value(value, cast)


def bw_fields(item, include_login=False):
    item = _ensure_item(item)
    fields = _custom_fields(item)
    if include_login:
        login = item.get('login') or {}
        if 'username' in login:
            fields.setdefault('username', login.get('username'))
        if 'password' in login:
            fields.setdefault('password', login.get('password'))
    return fields


def bw_value(item, field='password', default=_MISSING, required=None, cast=None):
    default_provided = default is not _MISSING
    if required is None:
        required = not default_provided

    value = _resolve_value(
        item,
        field=field,
        required=required,
        default_provided=default_provided,
        default_value=default,
        cast=cast,
        context=None,
    )
    return None if value is _MISSING else value


def _normalize_contract_spec(destination, config):
    if isinstance(config, str):
        return {'destination': destination, 'field': config, 'required': True}

    if not isinstance(config, Mapping):
        raise AnsibleFilterError(
            f'Contract entry `{destination}` must be a string field name or a mapping of options.'
        )

    spec = dict(config)
    spec.setdefault('destination', destination)
    spec.setdefault('field', destination.rsplit('.', 1)[-1])

    if 'required' not in spec:
        spec['required'] = 'default' not in spec

    return spec


def _set_path(target, destination, value):
    cursor = target
    parts = destination.split('.')
    for part in parts[:-1]:
        existing = cursor.get(part)
        if existing is None:
            cursor[part] = {}
            existing = cursor[part]
        elif not isinstance(existing, Mapping):
            raise AnsibleFilterError(
                f'Cannot assign `{destination}` because `{part}` already contains a non-mapping value.'
            )
        cursor = existing
    cursor[parts[-1]] = value


def bw_contract(item, spec, defaults=None):
    item = _ensure_item(item)

    if not isinstance(spec, Mapping):
        raise AnsibleFilterError('`bw_contract` expects `spec` to be a mapping keyed by destination paths.')

    result = copy.deepcopy(defaults) if defaults is not None else {}
    if not isinstance(result, Mapping):
        raise AnsibleFilterError('`bw_contract` expects `defaults` to be a mapping when provided.')

    result = dict(result)
    for destination, config in spec.items():
        field_spec = _normalize_contract_spec(destination, config)
        default_provided = 'default' in field_spec
        value = _resolve_value(
            item,
            field=field_spec['field'],
            required=field_spec['required'],
            default_provided=default_provided,
            default_value=field_spec.get('default'),
            cast=field_spec.get('cast'),
            context=f'Bitwarden contract destination `{destination}`',
        )
        if value is _MISSING:
            continue
        _set_path(result, field_spec['destination'], value)

    return result


def _sanitize_env_key(value):
    normalized = _ENV_KEY_RE.sub('_', value).strip('_')
    return normalized.upper()


def bw_prefixed(item, prefix, style='plain', include_login=True):
    if not prefix:
        raise AnsibleFilterError('`bw_prefixed` requires a non-empty `prefix`.')

    fields = bw_fields(item, include_login=include_login)

    if style == 'plain':
        return {f'{prefix}_{key}': value for key, value in fields.items()}

    if style == 'env':
        env_prefix = _sanitize_env_key(str(prefix))
        return {f'{env_prefix}_{_sanitize_env_key(key)}': value for key, value in fields.items()}

    raise AnsibleFilterError('`bw_prefixed` only supports `style="plain"` and `style="env"`.')


class FilterModule(object):
    def filters(self):
        return {
            'bw_fields': bw_fields,
            'bw_value': bw_value,
            'bw_contract': bw_contract,
            'bw_prefixed': bw_prefixed,
        }
