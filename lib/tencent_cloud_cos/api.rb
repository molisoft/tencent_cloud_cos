require 'rest-client'

module TencentCloudCos
  module Api

    # 默认分片大小 3M
    DEFAULT_SLICE_SIZE = 3 * 1024 * 1024


    def put(file, filename)
      config.method = 'put'
      config.uri    = filename
      content_type  = config.content_type
      src_filename = "attachment; filename=#{File.basename(file.path)}"

      authorization = Authorization.new(config)
      begin
        response = RestClient.put("#{config.host}#{config.uri}",
                                  file,
                                  Authorization: authorization.auth_header,
                                  host: config.host,
                                  content_length: file.size,
                                  content_type: content_type,
                                  content_disposition: src_filename)
      rescue RestClient::ExceptionWithResponse => e
        return e.response
      else
        return response
      end
    end

    # 分块上传(大文件)
    #   - 初始化
    #   - 分块上传
    #   - 完成
    #
    def put_slice(file, filename)
      upload_id = init_put_slice(file)
      raise 'Init slice fail' unless upload_id

      # 分块上传
      upload_slice(file, upload_id)

      # 完成
      complete_slice(upload_id)
    end

    def stat(filename)
    end

    def delete(filename)
      config.method = 'delete'
      config.uri = filename
      authorization = Authorization.new(config)
      begin
        response = RestClient.delete("#{config.host}#{config.uri}", file,
                                     Authorization: authorization.auth_header,
                                     host: config.host)
      rescue RestClient::ExceptionWithResponse => e
        return e.response
      else
        return response
      end
    end

    private

    # 关闭分块上传
    #
    def abort_slice(upload_id)
      config.method = 'delete'
      config.uri    = '/ObjectName'
      content_type  = config.content_type

      authorization = Authorization.new(config)
      begin
        response = RestClient.delete("#{config.host}/ObjectName?uploadId=#{upload_id}",
                                   '',
                                   Authorization: authorization.auth_header,
                                   host: config.host,
                                   content_length: file.size,
                                   content_type: content_type)
      rescue RestClient::ExceptionWithResponse => e
        return e.response
      else
        return response.code == 200
      end
    end

    # 分块上传
    #
    def upload_slice

    end
    # 完成分块上传
    def complete_slice(upload_id)

    end

    # 1、初始化分块上传
    def init_put_slice(file)
      config.method = 'post'
      config.uri    = '/Object'
      content_type  = config.content_type

      authorization = Authorization.new(config)
      begin
        response = RestClient.post("#{config.host}/Object?uploads",
                                  '',
                                  Authorization: authorization.auth_header,
                                  host: config.host,
                                  content_length: file.size,
                                  content_type: content_type)
      rescue RestClient::ExceptionWithResponse => e
        return e.response
      else
        result = parse_xml_to_hash(response.body)
        if result.has_key? 'InitiateMultipartUploadResult'
          return result['InitiateMultipartUploadResult']['UploadId']
        end
        return false
      end
    end

    def parse_xml_to_hash(xml)
      Hash.from_xml xml
    end
  end
end
