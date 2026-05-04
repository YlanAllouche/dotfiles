import os
import subprocess

from ranger.api.commands import Command


class toggle_flat(Command):
    """
    :toggle_flat

    Flattens or unflattens the directory view.
    """

    def execute(self):
        if self.fm.thisdir.flat == 0:
            self.fm.thisdir.unload()
            self.fm.thisdir.flat = -1
            self.fm.thisdir.load_content()
        else:
            self.fm.thisdir.unload()
            self.fm.thisdir.flat = 0
            self.fm.thisdir.load_content()


class fzf_select(Command):
    """
    :fzf_select
    Find a file using fzf.
    With a prefix argument to select only directories.

    See: https://github.com/junegunn/fzf
    """

    def execute(self):
        import os
        import subprocess

        from ranger.ext.get_executables import get_executables

        if "fzf" not in get_executables():
            self.fm.notify("Could not find fzf in the PATH.", bad=True)
            return

        fd = None
        if "fdfind" in get_executables():
            fd = "fdfind"
        elif "fd" in get_executables():
            fd = "fd"

        if fd is not None:
            hidden = "--hidden" if self.fm.settings.show_hidden else ""
            exclude = "--no-ignore-vcs --exclude '.git' --exclude '*.py[co]' --exclude '__pycache__'"
            only_directories = "--type directory" if self.quantifier else ""
            fzf_default_command = "{} --follow {} {} {} --color=always".format(
                fd, hidden, exclude, only_directories
            )
        else:
            hidden = (
                "-false" if self.fm.settings.show_hidden else r"-path '*/\.*' -prune"
            )
            exclude = r"\( -name '\.git' -o -name '*.py[co]' -o -fstype 'dev' -o -fstype 'proc' \) -prune"
            only_directories = "-type d" if self.quantifier else ""
            fzf_default_command = (
                "find -L . -mindepth 1 {} -o {} -o {} -print | cut -b3-".format(
                    hidden, exclude, only_directories
                )
            )

        env = os.environ.copy()
        env["FZF_DEFAULT_COMMAND"] = fzf_default_command
        env["FZF_DEFAULT_OPTS"] = (
            '--height=40% --layout=reverse --ansi --preview="{}"'.format(
                """
            (
                batcat --color=always {} ||
                bat --color=always {} ||
                cat {} ||
                tree -ahpCL 3 -I '.git' -I '*.py[co]' -I '__pycache__' {}
            ) 2>/dev/null | head -n 100
        """
            )
        )

        fzf = self.fm.execute_command(
            "fzf --no-multi", env=env, universal_newlines=True, stdout=subprocess.PIPE
        )
        stdout, _ = fzf.communicate()
        if fzf.returncode == 0:
            selected = os.path.abspath(stdout.strip())
            if os.path.isdir(selected):
                self.fm.cd(selected)
            else:
                self.fm.select_file(selected)


class touch_mkdir_p(Command):
    def execute(self):
        if not self.arg(1):
            self.fm.notify("File path required", bad=True)
            return

        path = self.arg(1)
        dirname = os.path.dirname(path)

        if dirname and not os.path.exists(dirname):
            os.makedirs(dirname)

        if not os.path.exists(path):
            open(path, "a").close()

        self.fm.notify("Created file: " + path)
        self.fm.reload_cwd()


class open_with_browser(Command):
    """
    :open_with_browser

    Open the selected file with $BROWSER environment variable.
    """

    def execute(self):
        if not self.fm.thisfile:
            self.fm.notify("No file selected", bad=True)
            return

        browser = os.environ.get("BROWSER")
        if not browser:
            self.fm.notify("$BROWSER environment variable not set", bad=True)
            return

        file_path = self.fm.thisfile.path
        try:
            subprocess.Popen([browser, file_path], start_new_session=True)
            self.fm.notify(f"Opened with {browser}")
        except Exception as e:
            self.fm.notify(f"Error opening file: {str(e)}", bad=True)
