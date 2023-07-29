require 'orthoses'
require 'rgot/cli'

Orthoses.logger.level = :error
exit Rgot::Cli.new(["-v", $PROGRAM_NAME, *ARGV]).run
