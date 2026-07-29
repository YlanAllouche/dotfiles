from __future__ import annotations

from collections.abc import Mapping, Sequence

from ansible.errors import AnsibleError
from ansible.plugins.loader import lookup_loader
from ansible.plugins.lookup import LookupBase


class LookupModule(LookupBase):
    def run(self, terms, variables=None, **kwargs):
        required = kwargs.pop('required', None)
        default_provided = 'default' in kwargs
        default_value = kwargs.pop('default', None)

        if kwargs.get('result_count', 1) != 1:
            raise AnsibleError('`bw_item` always resolves a single Bitwarden item and only supports `result_count=1`.')

        if required is None:
            required = not default_provided

        kwargs['result_count'] = 1
        plugin = self._load_bitwarden_lookup()

        results = []
        for term in terms:
            if isinstance(term, Mapping):
                results.append(term)
                continue

            if not isinstance(term, str) or not term:
                raise AnsibleError('`bw_item` expects each term to be a non-empty Bitwarden item name or an existing item object.')

            item = self._lookup_one_item(
                plugin=plugin,
                item_name=term,
                variables=variables,
                required=required,
                default_provided=default_provided,
                default_value=default_value,
                plugin_kwargs=kwargs,
            )
            results.append(item)

        return results

    def _load_bitwarden_lookup(self):
        try:
            plugin = lookup_loader.get('community.general.bitwarden', loader=self._loader, templar=self._templar)
        except Exception as exc:  # pragma: no cover - exercised through ansible runtime
            raise AnsibleError(
                'Unable to load `community.general.bitwarden`. Install the `community.general` collection on the Ansible controller.'
            ) from exc

        if plugin is None:
            raise AnsibleError(
                '`community.general.bitwarden` is unavailable. Install the `community.general` collection on the Ansible controller.'
            )

        return plugin

    def _lookup_one_item(self, *, plugin, item_name, variables, required, default_provided, default_value, plugin_kwargs):
        raw_results = plugin.run([item_name], variables=variables, **plugin_kwargs)

        if not isinstance(raw_results, Sequence):
            raise AnsibleError(
                f'`community.general.bitwarden` returned an unexpected type for `{item_name}`: {type(raw_results).__name__}.'
            )

        if not raw_results:
            if default_provided:
                return default_value
            if required:
                raise AnsibleError(f'Bitwarden item `{item_name}` was not found.')
            return None

        return raw_results[0]
