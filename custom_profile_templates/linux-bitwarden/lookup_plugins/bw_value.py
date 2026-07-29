from __future__ import annotations

from collections.abc import Mapping

from ansible.errors import AnsibleError
from ansible.plugins.loader import lookup_loader
from ansible.plugins.lookup import LookupBase


_MISSING = object()


class LookupModule(LookupBase):
    def run(self, terms, variables=None, **kwargs):
        field = kwargs.pop('field', 'password')
        cast = kwargs.pop('cast', None)
        required = kwargs.pop('required', None)
        default_provided = 'default' in kwargs
        default_value = kwargs.pop('default', None)

        if required is None:
            required = not default_provided

        results = []
        for term in terms:
            item = self._resolve_item(term, variables=variables, lookup_kwargs=kwargs)
            if item is None:
                if default_provided:
                    results.append(_cast_value(default_value, cast))
                    continue
                if required:
                    raise AnsibleError(f'Bitwarden item `{term}` was not found.')
                results.append(None)
                continue

            value = _resolve_value(
                item,
                field=field,
                required=required,
                default_provided=default_provided,
                default_value=default_value,
                cast=cast,
                context=f'Bitwarden item `{_item_name(item, fallback=term)}`',
            )
            results.append(value)

        return results

    def _resolve_item(self, term, *, variables, lookup_kwargs):
        if isinstance(term, Mapping):
            return term

        if not isinstance(term, str) or not term:
            raise AnsibleError('`bw_value` expects each term to be a Bitwarden item name or an existing item object.')

        plugin = lookup_loader.get('bw_item', loader=self._loader, templar=self._templar)
        if plugin is None:
            raise AnsibleError('Unable to load the local `bw_item` lookup plugin.')

        items = plugin.run([term], variables=variables, required=False, **lookup_kwargs)
        if not items:
            return None
        return items[0]


def _item_name(item, fallback):
    if isinstance(item, Mapping) and item.get('name'):
        return item['name']
    return fallback if isinstance(fallback, str) else '<inline item>'


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
        raise AnsibleError(f'Cannot cast value `{value}` to bool.')
    raise AnsibleError(f'Unsupported cast `{cast}`. Expected one of: str, int, float, bool, raw.')


def _resolve_value(item, *, field, required, default_provided, default_value, cast, context):
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
            raise AnsibleError(f'{context} is missing required field `{field_name}`.')
        return None

    return _cast_value(value, cast)
