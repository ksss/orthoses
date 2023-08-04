module ActiveSupportTest
  def test_active_support(t)
    Orthoses::Builder.new do
      use Orthoses::CreateFileByName,
        to: 'integration_test/tmp',
        depth: 2,
        rmtree: true
      use Orthoses::Filter do |name, content|
        name.start_with?("ActiveSupport") || name.start_with?("Integer")
      end
      use Orthoses::Constant, strict: false
      use Orthoses::Attribute
      use Orthoses::Mixin
      use Orthoses::ObjectSpaceAll
      use Orthoses::Autoload
      run -> () {
        require 'active_support'
      }
    end.call
  ensure
    Pathname('integration_test/tmp').rmtree rescue nil
  end
end
