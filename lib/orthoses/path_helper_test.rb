require 'tmpdir'
require 'fileutils'

module PathHelperTest
  def test_s_best_version_paths(t)
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        paths = Orthoses::PathHelper.best_version_paths("7.0", dir)
        unless paths.empty?
          t.error("expect empty, but got #{paths}")
          break
        end

        Dir.mkdir("6.0")
        FileUtils.touch("6.0/test1.rbs")
        Dir.mkdir("7.0")
        FileUtils.touch("7.0/test1.rbs")
        FileUtils.touch("7.0/test2.rbs")

        [
          { version: "5.0.0", path_ends: ["6.0/test1.rbs"] },
          { version: "6.0",   path_ends: ["6.0/test1.rbs"] },
          { version: "6.0.0", path_ends: ["6.0/test1.rbs"] },
          { version: "6.1.0", path_ends: ["6.0/test1.rbs"] },
          { version: "6.1.0", path_ends: ["6.0/test1.rbs"] },
          { version: "7.0.0", path_ends: ["7.0/test1.rbs", "7.0/test2.rbs"] },
          { version: "7.1.0", path_ends: ["7.0/test1.rbs", "7.0/test2.rbs"] },
        ].each do |test_case|
          paths = Orthoses::PathHelper.best_version_paths(test_case[:version], dir)
          unless paths.length == test_case[:path_ends].length
            t.error("expect #{test_case[:path_ends]}, but got #{paths}")
            break
          end

          unless paths.all? { |path| test_case[:path_ends].find { |path_end| path.end_with?(path_end) } }
            t.error("expect to find end with #{test_case[:path_ends]}, but got #{paths}")
          end
        end
      end
    end
  end
end
