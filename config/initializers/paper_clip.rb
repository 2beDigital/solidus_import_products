require "paperclip/railtie"
Paperclip::Railtie.insert
Paperclip.options[:content_type_mappings] = {:csv => "text/plain"}