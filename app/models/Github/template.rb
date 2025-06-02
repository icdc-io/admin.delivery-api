# frozen_string_literal: true

module Github
  class Template
    # def self.download_url(service_name)
    #   GithubClient.get_resource("templates/#{service_name}.json")['download_url']
    # end

    def self.find_by_service_name(service_name)
      GithubClient.get_githubusercontent_resource("templates/#{service_name}.json")
    end
  end
end
