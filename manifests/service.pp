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
#  * `actions` (array; optional; default `undef`)
#
#     This is a fairly complicated data structure designed to allow the
#     specification of multiple filespec/action sets in a single
#     `inoticoming` service.  It is mutually exclusive with the `action` /
#     `prefix` / `suffix` / `regexp` attributes.
#
#     Each element in the array passed to `actions` must be a hash,
#     containing a `command` key, as well as zero or more of the keys
#     `prefix`, `suffix`, or `regexp`.  They are used as follows:
#
#      * `command` -- The command to be run when a file matching the
#        associated `prefix`, `suffix`, and/or `regexp` appears in the
#        `directory` being watched.  If you wish to include the name of the
#        file which appeared in the command, you should use the placeholder
#        `'{}'` to indicate where the filename should be substituted.  The
#        single quotes are important, since the command will be interpreted
#        in the context of the shell.
#
#      * `prefix` -- Trigger this command on files which start with the
#        given string.
#
#      * `suffix` -- Trigger this command on files which end with the given
#        string.
#
#      * `regexp` -- Trigger this command on files which match the given
#        regular expression.
#
#  * `action` (string; optional; default `undef`)
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
		$actions       = undef,
		$action        = undef,
		$prefix        = undef,
		$suffix        = undef,
		$regexp        = undef,
		$initialsearch = false
) {
	include inoticoming::base

	if $actions and $action {
		fail "Only one of `actions` and `action` may be specified."
	}

	if !$actions and !$action {
		fail "Exactly one of `actions` and `action` must be specified."
	}

	if $action {
		if $prefix {
			$quoted_prefix = shellquote("--prefix", $prefix)
		}
		if $suffix {
			$quoted_suffix = shellquote("--suffix", $suffix)
		}
		if $regexp {
			$quoted_regexp = shellquote("--regexp", $regexp)
		}

		$inoticoming_service_command = "${quoted_prefix} ${quoted_suffix} ${quoted_regexp} $action \\;"
	} else {
		$inoticoming_service_command = inoticoming_command_from_actions($actions)
	}

	$quoted_directory = shellquote($directory)

	if $initialsearch {
		$initialsearch_opt = "--initialsearch"
	}

	daemontools::service { "inoticoming-${name}":
		user    => $user,
		command => "/usr/bin/inoticoming ${initialsearch_opt} --foreground ${quoted_directory} ${inoticoming_service_command}",
		enable  => true,
		require => Package["inoticoming"],
	}
}
