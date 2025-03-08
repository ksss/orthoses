require 'orthoses'
require 'rgot/cli'

Orthoses.logger.level = :error
unless $PROGRAM_NAME.end_with?("/rgot")
  at_exit do
    exit Rgot::Cli.new(["-v", "lib", "integration_test"]).run
  end
end
