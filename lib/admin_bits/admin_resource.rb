module AdminBits
  class AdminResource
    attr_reader :options, :resource, :request_params

    def initialize(resource, options, request_params = {})
      @resource       = resource
      @options        = options
      @request_params = request_params

      raise ":path must be provided" unless @options[:path]

      sanitize_params
    end

    def sanitize_params
      @request_params = request_params.
        with_indifferent_access.
        reject do |k,v|
          ["action", "controller", "commit"].include?(k) || v.blank?
        end

      request_params[:order] ||= default_order
      request_params[:asc]   ||= default_asc

      #raise @request_params.inspect
    end

    def default_order
      options[:default_order].to_s
    end

    def default_asc
      options[:default_direction] == :asc ? "true" : "false"
    end

    def output
      resource.order(get_order).page(get_page)
    end

    def url(params = {})
      Rails.application.routes.url_helpers.send(
        options[:path],
        request_params.merge(params)
      )
    end

    def get_page
      request_params[:page]
    end

    def get_order
      order = request_params[:order]

      if order.blank?
        nil
      else
        convert_mapping(options[:ordering][order.to_sym])
      end
    end

    def get_direction
      request_params[:asc] != "true" ? "DESC" : "ASC"
    end

    def convert_mapping(mapping)
      # Check if mapping was provided
      raise "No order mapping specified for '#{order}'" if mapping.blank?
      # Convert to array in order to simplify processing
      mapping = [mapping] if mapping.is_a?(String)
      # Convert to SQL form
      mapping.map {|m| "#{m} #{get_direction}"}.join(", ")
    end
  end
end