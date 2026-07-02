# frozen_string_literal: true

class UrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    uri = URI.parse(value)
    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      record.errors.add(attribute, options[:message] || "must be a valid HTTP/HTTPS URL")
    end
  rescue URI::InvalidURIError
    record.errors.add(attribute, "is not a valid URL")
  end
end
