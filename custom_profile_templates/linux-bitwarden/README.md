# Linux Bitwarden Template

This folder is a consumer-side starting point. Treat it like a small standalone
repo that imports the public dotfiles playbook and brings its own
controller-side Bitwarden abstraction.

Use it when you want:

- one Bitwarden item per mail account
- public roles to keep consuming neutral vars such as `email_accounts`
- a downstream wrapper that resolves secrets before the public roles run
- local plugin/config scope that stays inside this starter folder instead of the
  public dotfiles root

## Files

- `ansible.cfg`: scopes lookup/filter/vars plugin loading to this folder when
  copied into a downstream repo
- `main.yml`: imports the public repo; no Jinja-heavy consumer export file is
  needed
- `lookup_plugins/`, `filter_plugins/`, and `vars_plugins/`: local Bitwarden
  helpers for this consumer template only
- `vars/bitwarden.yml`: the single declarative consumer-side config file

## What You Edit

Most consumers only edit `vars/bitwarden.yml`.

That same file covers all of the supported patterns in this template:

- simple scalar values
- imported objects
- built-in contracts such as `email_account`
- custom YAML-defined contracts
- role exports such as `email_accounts`

You only need other files when:

- a mail account should use a file-backed signature in
  `files/mail/accounts/<id>/signature`
- you want to change the local Python helpers themselves instead of just adding
  more Bitwarden-backed entries

## Local helpers

This template ships its own small local Ansible helpers so the consumer vars can
stay almost entirely plain YAML instead of repeating inline Jinja transforms.

- `lookup('bw_item', 'name')`: fetch one Bitwarden item by name
- `lookup('bw_value', 'name', field='address')`: fetch one value directly; when
  `field` is omitted it returns the login password
- `item | bw_value(field='address')`: extract one value from an already-fetched
  item
- `item | bw_fields(include_login=true)`: import the resolved item as one plain
  dict
- `item | bw_prefixed(prefix='mail_perso')`: import a whole item into one
  prefixed dict
- `vars_plugins/bitwarden_consumer.py`: auto-loads `vars/bitwarden.yml`,
  resolves the Bitwarden model, and exports neutral public-role vars

The low-level helpers stay available, but the intended consumer-side pattern is:

1. declare everything under one top-level `bitwarden:` object
2. let the local vars plugin resolve bindings, values, objects, and role exports
3. let the public roles consume only neutral vars such as `email_accounts`

## Declarative Model

The single `vars/bitwarden.yml` file demonstrates four main sections:

- `bitwarden.bindings`: where each local name fetches its Bitwarden item and
  optionally declares a contract such as `email_account`
- `bitwarden.values`: simple scalar values; omitted `field` means login password
- `bitwarden.objects`: either a plain dict of fields or a prefixed env-style map
- `bitwarden.role_exports`: publish contract results into role-native vars such
  as `email_accounts`

The mail example keeps the public `email` role unchanged. The downstream wrapper
declares one `mail_perso` binding with `contract: email_account`, then lets the
local vars plugin export `mail_perso`, `email_accounts`, and
`email_primary_account_id` automatically.

## Pattern Cookbook

### 1. One value from one entry

Use this when you want a normal top-level Ansible var.

```yaml
bitwarden:
  bindings:
    llm_openai:
      item: llm/openai

  values:
    openai_api_key:
      binding: llm_openai
```

`field` is optional here. When omitted, the value defaults to the Bitwarden
login password.

Named field example:

```yaml
bitwarden:
  bindings:
    mail_perso:
      item: mail-account/perso

  values:
    identity_git_email:
      binding: mail_perso
      field: address
```

### 2. Import a whole entry as one object

Use `style: fields` for a plain dict of field names to values.

```yaml
bitwarden:
  bindings:
    mail_perso:
      item: mail-account/perso

  objects:
    mail_perso_fields:
      binding: mail_perso
      style: fields
```

Use `style: env` for an env-style dict with an inferred prefix from the binding
name.

```yaml
bitwarden:
  bindings:
    mail_perso:
      item: mail-account/perso

  objects:
    mail_perso_env:
      binding: mail_perso
      style: env
```

That exports `mail_perso_env` as a dict with keys like:

- `MAIL_PERSO_ADDRESS`
- `MAIL_PERSO_SMTP_PASSWORD`

### 3. Bind an entry to a built-in contract

Use this when a public role already expects a structured object shape.

```yaml
bitwarden:
  bindings:
    mail_perso:
      item: mail-account/perso
      contract: email_account

  role_exports:
    email:
      contract: email_account
      primary: mail_perso
```

This automatically exports:

- `mail_perso`
- `email_accounts`
- `email_primary_account_id`

### 4. Define your own contract in YAML

Use `contract_definitions` when you want a structured object but do not need a
new Python preset.

```yaml
bitwarden:
  bindings:
    smtp_app:
      item: app/smtp
      contract: smtp_login

  contract_definitions:
    smtp_login:
      host: smtp_host
      port:
        field: smtp_port
        cast: int
      username: smtp_user
      password: smtp_password
```

This exports `smtp_app` as the resolved contract object.

### 5. Override a built-in or custom contract

Use `contract_overrides` when the contract shape is right but a field should be
made optional, defaulted, or cast differently.

```yaml
bitwarden:
  contract_overrides:
    email_account:
      realname:
        default: Your Name
```

Binding-level `overrides:` and `defaults:` can still customize one specific
binding.

## Automatic Exports

The local vars plugin automatically publishes these results as normal top-level
Ansible vars:

- entries from `bitwarden.values`
- entries from `bitwarden.objects`
- each contract-bound binding, such as `mail_perso`
- role-native exports such as `email_accounts` and `email_primary_account_id`

It also publishes one debug-friendly aggregate object:

- `bitwarden_resolved`

That means the public roles do not need to know anything about Bitwarden.

## Defining More Contracts

There are two ways to add another contract:

1. Prefer `bitwarden.contract_definitions` when a YAML mapping is enough.
2. Edit `vars_plugins/bitwarden_consumer.py` only when you need new built-in
   behavior or a new role export strategy.

For most downstream cases, a YAML-defined contract is enough because it already
supports:

- source field selection
- required vs optional fields
- defaults
- simple casts such as `int` and `bool`

The current template only has one built-in role export:

- `bitwarden.role_exports.email`

Custom contracts still export their resolved object through the binding name,
even if they do not participate in a role export.

### Conventions

To keep the YAML short, the built-in `email_account` contract applies a few
consumer-side conventions:

- a binding named `mail_perso` implies `id: perso`
- `maildir` defaults to the same inferred id
- the mail sync/send baseline defaults are filled in automatically
- `primary` is set from `bitwarden.role_exports.email.primary`
- `signature_src` is inferred from `files/mail/accounts/<id>/signature` when
  that file exists

You can still override any of those through binding-level `defaults:` or
contract overrides when needed.

## Expected Bitwarden setup

The lookup runs on the Ansible controller.

- install the collection: `ansible-galaxy collection install community.general`
- install the official Bitwarden CLI where `ansible-playbook` runs
- authenticate and unlock before running the playbook

Example:

```bash
bw login
export BW_SESSION="$(bw unlock --raw)"
ansible-playbook main.yml
```

If you copy this folder into its own repo, keep `ansible.cfg` next to `main.yml`
and run Ansible from that repo so the local lookup/filter/vars plugins are
loaded.

## Expected item shape

Each mail account uses one Bitwarden item named like `mail-account/<id>`.

The examples assume custom fields that mirror the public `email_accounts`
contract:

- `address`
- `realname`
- `maildir`
- `imap_host`
- `imap_port`
- `imap_user`
- `imap_password`
- `imap_auth_mechs`
- `imap_ssl_type`
- `smtp_host`
- `smtp_port`
- `smtp_user`
- `smtp_password`
- `smtp_tls_starttls`

Whole-item lookups do not enforce that every custom field exists. The local
contract preset decides which fields are required, which ones are optional, and
which ones keep built-in defaults.

For the built-in `email_account` contract in this template, the current required
fields are:

- `address`
- `imap_host`
- `imap_port`
- `imap_user`
- `imap_password`
- `smtp_host`
- `smtp_port`
- `smtp_user`
- `smtp_password`

The current optional fields are:

- `realname`
- `maildir`
- `imap_auth_mechs`
- `imap_ssl_type`
- `smtp_tls_starttls`

The example also derives `identity_git_name`, `identity_git_email`, a plain
field dict, and an env-style dict from the same Bitwarden item to show how one
source can satisfy several downstream needs without needing a separate Jinja
export file.
