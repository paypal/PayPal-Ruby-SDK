require_relative '../../lib/paypal/core/version'
require 'webmock/rspec'

include WebMock::API

describe PayPal::PayPalHttpClient do
  before do
    WebMock.disable!
    @environment = PayPal::SandboxEnvironment.new('clientId', 'clientSecret')
    @httpClient = PayPal::PayPalHttpClient.new(@environment)
  end

  after do
    WebMock.disable!
  end

  # Helpers
  def stubAccessToken
    access_token_json = JSON.generate({
      :access_token => "simple-access-token",
      :expires_in => 3600,
      :token_type => 'Bearer',
    })

    stub_request(:any, @environment.base_url + "/v1/oauth2/token").
      to_return(body: access_token_json, status: 200,
                headers: {'content-type' => "application/json"})
  end

  def stubRefreshToken
    access_token_json = JSON.generate({
      :access_token => "refresh-access-token",
      :expires_in => 3600,
      :token_type => 'Bearer',
    })

    stub_request(:any, @environment.base_url + "/v1/oauth2/token")
      .to_return(body: access_token_json, status: 200, headers: {'content-type' => "application/json"})
  end

  describe 'execute' do
    before(:each) do
      WebMock.enable!
    end

    after(:each) do
      WebMock.disable!
    end

    it 'fetches access token if not yet fetched' do
      access_token_stub = stubAccessToken

      return_json = JSON.generate({
        :some_key => "some_value",
      })

      stub_request(:get, @environment.base_url + "/path")
        .to_return(body: return_json, status: 200, headers: {'content-type' => "application/json"})

      req = OpenStruct.new({:verb => "GET", :path => "/path"})

      resp = @httpClient.execute(req)

      expect(resp.status_code).to eq(200)
      expect(resp.result.some_key).to eq("some_value")
      assert_requested(access_token_stub)
    end

    it 'does not fetch access token if not expired and valid' do
      access_token_stub = stubAccessToken

      return_json = JSON.generate({
        :some_key => "some_value",
      })

      response_stub = stub_request(:any, @environment.base_url)
        .to_return(body: return_json, status: 200, headers: {'content-type' => "application/json"})

      req = OpenStruct.new({:verb => "GET", :path => "/"})

      resp = @httpClient.execute(req)

      expect(resp.status_code).to eq(200)
      expect(resp.result[:some_key]).to eq("some_value")

      resp = @httpClient.execute(req)

      assert_requested(access_token_stub, times: 1)
      assert_requested(response_stub, times: 2)
    end

    it 'fetches access token if expired' do
      expired_access_token_json = JSON.generate({
        :access_token => "expired-access-token",
        :expires_in => -1,
        :token_type => 'Bearer',
      })

      access_token_json = JSON.generate({
        :access_token => "simple-access-token",
        :expires_in => 3600,
        :token_type => 'Bearer',
      })

      access_token_stub = stub_request(:any, @environment.base_url + "/v1/oauth2/token")
        .to_return(body: expired_access_token_json, status: 200, headers: {'content-type' => "application/json"})
        .times(1)
        .then
        .to_return(body: access_token_json, status: 200, headers: {'content-type' => "application/json"})

      return_json = JSON.generate({
        :some_key => "some_value",
      })

      response_stub = stub_request(:any, @environment.base_url)
        .to_return(body: return_json, status: 200, headers: {'content-type' => "application/json"})

      req = OpenStruct.new({:verb => "GET", :path => "/"})

      resp = @httpClient.execute(req)

      expect(resp.status_code).to eq(200)
      expect(resp.result[:some_key]).to eq("some_value")

      resp = @httpClient.execute(req)

      assert_requested(access_token_stub, times: 2)
      assert_requested(response_stub, times: 2)
    end

    it 'fetches access token with refresh token not yet fetched' do
      @httpClient = PayPal::PayPalHttpClient.new(@environment, "refresh-token")
      refresh_token_stub = stubRefreshToken

      return_json = JSON.generate({
        :some_key => "some_value",
      })

      stub_request(:any, @environment.base_url)
        .to_return(body: return_json, status: 200, headers: {'content-type' => "application/json"})

      req = OpenStruct.new({:verb => "GET", :path => "/"})

      resp = @httpClient.execute(req)

      expect(resp.status_code).to eq(200)
      expect(resp.result[:some_key]).to eq("some_value")
      assert_requested(refresh_token_stub)
    end

    it 'fetches access token with refresh token if expired' do
      @httpClient = PayPal::PayPalHttpClient.new(@environment, "refresh-token")

      expired_access_token_json = JSON.generate({
        :access_token => "expired-access-token",
        :expires_in => -1,
        :token_type => 'Bearer',
      })

      access_token_json = JSON.generate({
        :access_token => "refresh-access-token",
        :expires_in => 3600,
        :token_type => 'Bearer',
      })

      access_token_stub = stub_request(:any, @environment.base_url + "/v1/oauth2/token")
        .to_return(body: expired_access_token_json, status: 200, headers: {'content-type' => "application/json"})
        .times(1)
        .then
        .to_return(body: access_token_json, status: 200, headers: {'content-type' => "application/json"})

      return_json = JSON.generate({
        :some_key => "some_value",
      })

      response_stub = stub_request(:any, @environment.base_url)
        .to_return(body: return_json, status: 200, headers: {'content-type' => "application/json"})

      req = OpenStruct.new({:verb => "GET", :path => "/"})

      resp = @httpClient.execute(req)

      expect(resp.status_code).to eq(200)
      expect(resp.result[:some_key]).to eq("some_value")

      resp = @httpClient.execute(req)

      assert_requested(access_token_stub, times: 2)
      assert_requested(response_stub, times: 2)
    end

    it 'does not fetch access token if authorization header already present' do
      @httpClient = PayPal::PayPalHttpClient.new(@environment)

      return_json = JSON.generate({
        :some_key => "some_value",
      })

      stub_request(:get, @environment.base_url + "/path")
        .to_return(body: return_json, status: 200, headers: {'content-type' => "application/json"})

      req = OpenStruct.new({:verb => "GET", :path => "/path", :headers => {'Authorization' => 'custom-header-value'}})

      resp = @httpClient.execute(req)

      expect(resp.status_code).to eq(200)
      expect(resp.result[:some_key]).to eq("some_value")

      expect(WebMock).to have_requested(:get, @environment.base_url + '/path')
                           .with(headers: {'Authorization' => "custom-header-value"})
    end

    it 'sets Authorization header with access token value' do
      access_token_stub = stubAccessToken

      return_json = JSON.generate({
        :some_key => "some_value",
      })

      stub_request(:get, @environment.base_url + "/path")
        .to_return(body: return_json, status: 200, headers: {'content-type' => "application/json"})

      req = OpenStruct.new({:verb => "GET", :path => "/path"})

      resp = @httpClient.execute(req)

      expect(resp.status_code).to eq(200)
      expect(resp.result.some_key).to eq("some_value")
      assert_requested(access_token_stub)

      expect(WebMock).to have_requested(:get, @environment.base_url + '/path')
                           .with(headers: {'Authorization' => "Bearer simple-access-token"})
    end

    it 'sets User-Agent header properly' do
      access_token_stub = stubAccessToken

      return_json = JSON.generate({
        :some_key => "some_value",
      })

      request_stub = stub_request(:any, @environment.base_url)
        .to_return(body: return_json, status: 200, headers: {'content-type' => "application/json"})

      resp = @httpClient.execute(OpenStruct.new({:verb => "GET", :path => "/"}))

      user_agent_regex = /^PayPalSDK\/rest-sdk-ruby #{PayPal::VERSION} \(paypal-sdk-core .*; ruby [\d\.?]*p\d+-.*;OpenSSL.*\)$/
      expect(WebMock).to have_requested(:get, @environment.base_url)
                           .with(headers: {'User-Agent' => user_agent_regex})
    end

    it 'sets Accept-Encoding header to gzip' do
      access_token_stub = stubAccessToken

      return_json = JSON.generate({
        :some_key => "some_value",
      })

      request_stub = stub_request(:any, @environment.base_url)
        .to_return(body: return_json, status: 200, headers: {'content-type' => "application/json"})

      req = OpenStruct.new({:verb => "GET", :path => "/"})

      resp = @httpClient.execute(req)

      expect(resp.status_code).to eq(200)
      expect(resp.result[:some_key]).to eq("some_value")
      expect(WebMock).to have_requested(:get, @environment.base_url)
                           .with(headers: {'Accept-Encoding' => 'gzip'})
    end
  end
end
