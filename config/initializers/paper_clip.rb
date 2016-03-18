require "paperclip/railtie"
Paperclip::Railtie.insert
Paperclip.options[:content_type_mappings] = {:csv => "text/plain"}

Paperclip.interpolates :timestamp do |attachment, style|
  attachment.instance_read(:updated_at).strftime("%Y%m%d%H%M%S")
end