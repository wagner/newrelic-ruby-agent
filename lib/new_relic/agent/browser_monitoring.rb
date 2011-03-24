require 'base64'

module NewRelic
  module Agent
    module BrowserMonitoring
      
      def browser_timing_short_header
        return "" if NewRelic::Agent.instance.browser_monitoring_key.nil?

        "<script>var NREUMQ=[];NREUMQ.push([\"mark\",\"firstbyte\",new Date().getTime()])</script>"
      end
      
      def browser_timing_header        
        return "" if NewRelic::Agent.instance.browser_monitoring_key.nil?
        
        @header_script ||= begin
          puts "compute header"
          episodes_url = NewRelic::Agent.instance.episodes_url
        
          load_js = "(function(){var d=document;var e=d.createElement(\"script\");e.type=\"text/javascript\";e.async=true;e.src=\"#{episodes_url}\";var s=d.getElementsByTagName(\"script\")[0];s.parentNode.insertBefore(e,s);})()"
          
          "<script>var NREUMQ=[];NREUMQ.push([\"mark\",\"firstbyte\",new Date().getTime()]);#{load_js}</script>"
        end
        
        @header_script
      end
      
      def browser_timing_footer        
        license_key = NewRelic::Agent.instance.browser_monitoring_key
        
        return "" if license_key.nil?

        application_id = NewRelic::Agent.instance.application_id
        beacon = NewRelic::Agent.instance.beacon
        transaction_name = Thread::current[:newrelic_scope_name] || "<unknown>"
        obf = obfuscate(transaction_name)
        
        frame = Thread.current[:newrelic_metric_frame]
        
        if frame && frame.start
          # HACK ALERT - there's probably a better way for us to get the queue-time
          queue_time = ((Thread.current[:queue_time] || 0).to_f * 1000.0).round
          app_time = ((Time.now - frame.start).to_f * 1000.0).round
 
<<-eos
<script type="text/javascript" charset="utf-8">NREUMQ.push(["nrf2","#{beacon}","#{license_key}",#{application_id},"#{obf}",#{queue_time},#{app_time}])</script>
eos
        end
      end
      
      private

      def obfuscate(text)
        obfuscated = ""
        
        key = NewRelic::Control.instance.license_key
        
        text.bytes.each_with_index do |byte, i|
          obfuscated.concat((byte ^ key[i % 13]))
        end
        
        [obfuscated].pack("m0").chomp
      end
    end
  end
end
