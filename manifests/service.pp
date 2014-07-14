# Instantiate a service to watch a specific directory for specific files,
# and execute programs when a file matching the specifier appear.
#
# So, that's three concepts:
#
#  * **A specific directory**.  This is straightforward.  A single
#    inoticoming service can watch exactly one directory.  It does not
#    traverse subdirectories or otherwise do anything fancy.
#
#  * **Specific files**.  You can match files which have a particular
#    `suffix`, a particular `prefix`, or which match a given `regexp`.
#
#  * **Execute programs**.  You can run whatever you like when a file
#    matching your conditions appears.  For simplicity, this type only
#    supports running a single command, but if you need to do something
#    complex, you can wrap it all up in a script.  Note that if you want to
#    get rid of the file afterwards, you have to do that yourself in your
#    script -- `inoticoming` does not delete files itself.
#
# Available attributes:
#
#  * `user` (string; required)
#
#     The user to run the service as.  This user must have permissions to
#     the `directory`, and also to do everything that the `action` needs.
#
#  * `directory` (string; required)
#
#     The directory to watch for changes.
#
#  * `action` (string; required)
#
#     The command to run.  If you wish to include the name of the file which
#     was passed, you should add `'{}'` (the quotes are important, since
#     this command will be executed in the shell) to the command line in the
#     appropriate place.
#
#  * `prefix` (string; optional; default `undef`)
#
#     Only trigger on files which start with the given string.
#
#  * `suffix` (string; optional; default `undef`)
#
#     Only trigger on files which end with the given string.
#
#  * `regexp` (string; optional; default `undef`)
#
#     Only trigger on files which match the given regular expression.
#
#  * `initialsearch` (boolean; optional; default `false`)
#
#    If you expect to have files in your `directory` before this service
#    starts, then you can set `initialsearch` to `true` to have
#    `inoticoming` process those pre-existing files before moving on to
#    newly created files.  Files which appear during the initial processing
#    *may* be processed twice.
#
define inoticoming::service(
		$user,
		$directory,
		$action,
		$prefix        = undef,
		$suffix        = undef,
		$regexp        = undef,
		$initialsearch = false
) {
	include inoticoming::base

	$quoted_directory = shellquote($directory)
	if $prefix {
		$quoted_prefix = shellquote("--prefix", $prefix)
	}
	if $suffix {
		$quoted_suffix = shellquote("--suffix", $suffix)
	}
	if $regexp {
		$quoted_regexp = shellquote("--regexp", $regexp)
	}
	if $initialsearch {
		$initialsearch_opt = "--initialsearch"
	}

	daemontools::service { "inoticoming-${name}":
		user    => $user,
		command => "/usr/bin/inoticoming $initialsearch_opt --foreground ${quoted_directory} ${quoted_prefix} ${quoted_suffix} ${quoted_regexp} $action \\;",
		enable  => true
	}
}
