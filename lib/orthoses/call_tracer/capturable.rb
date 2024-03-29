# frozen_string_literal: true

module Orthoses
  class CallTracer
    module Capturable
      module ExtractRestParameters
        def __extract_rest_parameters__(*rest, **kw_rest, &block)
          {
            :* => rest,
            :** => kw_rest,
            :& => block,
            :"..." => [rest, kw_rest, block]
          }
        end
      end

      def build_capture(tp)
        Capture.new(
          method: build_method(tp),
          argument: build_argument(tp),
        )
      end

      private

      def build_method(tp)
        METHOD_METHOD.bind(tp.self).call(tp.method_id)
      end

      def build_argument(tp)
        has_unnamed_parameters = false
        tp.parameters.each_with_object({}) do |op_name, hash|
          name = op_name[1]
          case name
          when :*, :**, :&, nil
            has_unnamed_parameters = true
          else
            hash[name] = tp.binding.local_variable_get(name).then do |var|
              case var
              when Module, Thread::Backtrace::Location, IO, Encoding
                var
              else
                var.dup
              end
            rescue => err
              warn("#{var.class}#dup failed with #{err.class}:#{err.message}")
              var
            end
          end
        end.tap do |hash|
          if has_unnamed_parameters
            tp.binding.eval("extend ::Orthoses::CallTracer::Capturable::ExtractRestParameters")
            unnamed_parameters = tp.binding.eval("__extract_rest_parameters__(...)")
            hash.merge!(unnamed_parameters)
          end
        end
      end
    end
  end
end
