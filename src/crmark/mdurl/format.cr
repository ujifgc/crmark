module MarkdownIt
  module MDUrl
    module Format
      def self.format(url)
        result = ""

        result += url.protocol || ""
        result += url.slashes ? "//" : ""
        result += url.auth ? "#{url.auth}@" : ""

        hostname = url.hostname
        if hostname && hostname.index(':')
          # ipv6 address
          result += "[" + hostname + "]"
        else
          result += hostname || ""
        end

        result += url.port ? ":#{url.port}" : ""
        result += url.pathname || ""
        result += url.search || ""
        result += url.hash || ""

        return result
      end
      
    end
  end
end
