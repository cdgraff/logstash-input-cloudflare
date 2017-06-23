input {
    cloudflare {
        auth_email => "CF_AUTH_EMAIL"
        auth_key => "CF_AUTH_KEY"
        domain => "CF_DOMAIN"
        type => "cloudflare_logs"
        poll_time => 15
        poll_interval => 120
        metadata_filepath => "/tmp/cf_metadata.json"
        fields => [
          'timestamp', 'zoneId', 'ownerId', 'zoneName', 'rayId', 'securityLevel',
          'client.ip', 'client.country', 'client.sslProtocol', 'client.sslCipher',
          'client.deviceType', 'client.asNum', 'clientRequest.bytes',
          'clientRequest.httpHost', 'clientRequest.httpMethod', 'clientRequest.uri',
          'clientRequest.httpProtocol', 'clientRequest.userAgent', 'cache.cacheStatus',
          'edge.cacheResponseTime', 'edge.startTimestamp', 'edge.endTimestamp',
          'edgeResponse.status', 'edgeResponse.bytes', 'edgeResponse.bodyBytes',
          'originResponse.status', 'origin.responseTime'
        ]
    }
}
output {
    elasticsearch {
        hosts => ["elasticsearch:9200"]
        index => "logstash-%{+YYYY.MM.dd}"
        doc_as_upsert => true
        document_id => "%{rayId}"
        template_overwrite => true
    }
}
filter {
    ruby {
        code => "event.set('timestamp_ms', event.get('timestamp') / 1_000_000)"
        remove_field => ['timestamp']
    }
    ruby {
        code => "event.set('edge_requestTime', event.get('edge_endTimestamp') - event.get('edge_startTimestamp').to_f / 1_000_000_000)"
    }
    ruby {
        code => "event.set('edgeResponse_headerBytes', event.get('edgeResponse_bytes').to_i - event.get('edgeResponse_bodyBytes').to_i)"
    }
    date {
        match => ["timestamp_ms", "UNIX_MS"]
    }
    geoip {
        source => "client_ip"
    }
    useragent {
        source => "clientRequest.userAgent"
    }
}
