module ActiveSupportTest
  def test_active_support(t)
    Orthoses::Builder.new do
      use Orthoses::CreateFileByName,
        base_dir: 'integration_test/tmp'
      use Orthoses::Filter,
        if: ->(name, content) {
          name.start_with?("ActiveSupport") || name.start_with?("Integer")
        }
      use Orthoses::Constant
      use Orthoses::IncludeExtendPrepend
      use Orthoses::ObjectSpaceAll
      run -> () {
        require 'active_support'
        Orthoses::Util.unautoload!
      }
    end.call
  ensure
    Pathname('integration_test/tmp').rmtree rescue nil
  end
end
