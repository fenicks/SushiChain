# Copyright © 2017-2020 The Axentro Core developers
#
# See the LICENSE file at the top-level directory of this distribution
# for licensing information.
#
# Unless otherwise agreed in a custom licensing agreement with the Axentro Core developers,
# no part of this software, including this file, may be copied, modified,
# propagated, or distributed except according to the terms contained in the
# LICENSE file.
#
# Removal or modification of this copyright notice is prohibited.

require "./logger"

module ::Axentro::Core
  abstract class HandleSocket
    def send(socket, t, content)
      json_content = content.to_json
      m = {type: t, content: json_content}.to_json
      debug "sending message of type #{t} and size #{m.size}" if (t != 257) && (t != 22) && (t != 23)
      socket.send(m)
    rescue e : Exception
      handle_exception(socket, e)
    end

    def handle_exception(socket : HTTP::WebSocket, e : Exception)
      debug "Exception triggered when sending message: #{e}"
      case e
      when IO::Error
        clean_connection(socket)
      when Errno
        if error_message = e.message
          if error_message == "Error writing to socket: Broken pipe"
            clean_connection(socket)
          elsif error_message == "Error writing to socket: Protocol wrong type for socket"
            clean_connection(socket)
          elsif error_message == "Connection refused"
            clean_connection(socket)
          elsif error_message == "Connection reset by peer"
            clean_connection(socket)
          else
            show_exception(e)
          end
        else
          show_exception(e)
        end
      else
        show_exception(e)
      end
    end

    def show_exception(e : Exception)
      if error_message = e.message
        error error_message
      else
        error "unknown error"
      end

      if backtrace = e.backtrace
        error backtrace.join("\n")
      end
    end

    abstract def clean_connection(socket)

    include Logger
  end
end
