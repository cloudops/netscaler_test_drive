<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
    <title>Control Panel</title>
    <link rel="stylesheet" type="text/css" href="/static/css/iphone-toggle.css">
    <link rel="stylesheet" type="text/css" href="/static/css/style.css">
    <script src="/static/js/jquery-1.10.2.min.js"></script>
    <script type="text/javascript" src="/static/js/json2.js"></script>
    <script type="text/javascript" src="http://www.google.com/jsapi"></script>
    <script type="text/javascript">
      google.load('visualization', '1', {packages: ['annotatedtimeline']});
    </script>
    <script type="text/javascript">
      var countdown;
      function drawVisualizations() {
        $(".refresh-in").html(59);
        clearInterval(countdown);
        countdown = setInterval(function(){
          sec=parseInt($(".refresh-in").html()); 
          if (sec != 0) {
            $(".refresh-in").html(sec-1);
          }
        },1000);

        var cpu_qa = {  
          "namespace": "AWS/EC2",       // CloudWatch namespace (string)
          "metric": "CPUUtilization",   // CloudWatch metric (string)
          "unit": "Percent",            // CloudWatch unit (string)
          "statistics": ["Average"],      // CloudWatch statistics (list of strings)
          "period": 600,                // CloudWatch period (int)
          "cloudwatch_queries":         // (list of dictionaries)
          [   
            {
              "prefix": "CPU ",   // label prefix for associated data sets (string)
              "dimensions": { "InstanceId": "i-f361b7c4"}, // CloudWatch dimensions (dictionary)
              "region": "us-west-2"
            }
          ]
        };

        var mem_qa = {  
          "namespace": "System/Linux",       // CloudWatch namespace (string)
          "metric": "MemoryUtilization",   // CloudWatch metric (string)
          "unit": "Percent",            // CloudWatch unit (string)
          "statistics": ["Average"],      // CloudWatch statistics (list of strings)
          "period": 600,                // CloudWatch period (int)
          "cloudwatch_queries":         // (list of dictionaries)
          [   
            {
              "prefix": "Memory ",   // label prefix for associated data sets (string)
              "dimensions": { "InstanceId": "i-f361b7c4"}, // CloudWatch dimensions (dictionary)
              "region": "us-west-2"
            }
          ]
        };

        var network_in_qa = {  
          "namespace": "AWS/EC2",       // CloudWatch namespace (string)
          "metric": "NetworkIn",   // CloudWatch metric (string)
          "unit": "Bytes",            // CloudWatch unit (string)
          "statistics": ["Average"],      // CloudWatch statistics (list of strings)
          "period": 600,                // CloudWatch period (int)
          "cloudwatch_queries":         // (list of dictionaries)
          [   
            {
              "prefix": "Network In ",   // label prefix for associated data sets (string)
              "dimensions": { "InstanceId": "i-f361b7c4"}, // CloudWatch dimensions (dictionary)
              "region": "us-west-2"
            }
          ]
        };

        var network_out_qa = {  
          "namespace": "AWS/EC2",       // CloudWatch namespace (string)
          "metric": "NetworkOut",   // CloudWatch metric (string)
          "unit": "Bytes",            // CloudWatch unit (string)
          "statistics": ["Average"],      // CloudWatch statistics (list of strings)
          "period": 600,                // CloudWatch period (int)
          "cloudwatch_queries":         // (list of dictionaries)
          [   
            {
              "prefix": "Network Out ",   // label prefix for associated data sets (string)
              "dimensions": { "InstanceId": "i-f361b7c4"}, // CloudWatch dimensions (dictionary)
              "region": "us-west-2"
            }
          ]
        };


        var cpu_query = new google.visualization.Query('http://'+window.location.host+'/get_data?qs='+JSON.stringify(cpu_qa));
        cpu_query.send(function(response) {
          if (response.isError()) {
            alert('CloudWatch query: ' + response.getMessage() + ' ' + response.getDetailedMessage());
            return;
          }
      
          var data = response.getDataTable();
          var visualization = new google.visualization.AnnotatedTimeLine(document.getElementById('cpu_utilization'));
          visualization.draw(data, { 
            'allowRedraw': true, 
            'displayAnnotations': false, 
            'fill': 20,
            'legendPosition': 'newRow',
            'allValuesSuffix': '%'})
        });

        var mem_query = new google.visualization.Query('http://'+window.location.host+'/get_data?qs='+JSON.stringify(mem_qa));
        mem_query.send(function(response) {
          if (response.isError()) {
            alert('CloudWatch query: ' + response.getMessage() + ' ' + response.getDetailedMessage());
            return;
          }
      
          var data = response.getDataTable();
          var visualization = new google.visualization.AnnotatedTimeLine(document.getElementById('mem_utilization'));
          visualization.draw(data, {   
            'allowRedraw': true,
            'displayAnnotations': false, 
            'fill': 20,
            'legendPosition': 'newRow',
            'allValuesSuffix': '%'})
        });

        var network_in_query = new google.visualization.Query('http://'+window.location.host+'/get_data?qs='+JSON.stringify(network_in_qa));
        network_in_query.send(function(response) {
          if (response.isError()) {
            alert('CloudWatch query: ' + response.getMessage() + ' ' + response.getDetailedMessage());
            return;
          }
      
          var data = response.getDataTable();
          var visualization = new google.visualization.AnnotatedTimeLine(document.getElementById('network_in'));
          visualization.draw(data, {   
            'allowRedraw': true,
            'displayAnnotations': false, 
            'fill': 20,
            'legendPosition': 'newRow',
            'allValuesSuffix': 'Bytes'})
        });

        var network_out_query = new google.visualization.Query('http://'+window.location.host+'/get_data?qs='+JSON.stringify(network_out_qa));
        network_out_query.send(function(response) {
          if (response.isError()) {
            alert('CloudWatch query: ' + response.getMessage() + ' ' + response.getDetailedMessage());
            return;
          }
      
          var data = response.getDataTable();
          var visualization = new google.visualization.AnnotatedTimeLine(document.getElementById('network_out'));
          visualization.draw(data, {   
            'allowRedraw': true,
            'displayAnnotations': false, 
            'fill': 20,
            'legendPosition': 'newRow',
            'allValuesSuffix': 'Bytes'})
        });
      }
      
      google.setOnLoadCallback(drawVisualizations);
      setInterval('drawVisualizations()', 60000);

      $(function() {
        var save_in = 3; // seconds

        // netscaler config save
        var netscaler_timeout;
        var netscaler_config_save;
        $(".netscaler .iphone-toggle-buttons input").on('change', function(e) {
          clearTimeout(netscaler_timeout);
          clearTimeout(netscaler_config_save);
          $('.netscaler .status .processing .loader-text').html("Saving in <span>"+save_in+"</span>...");
          $('.netscaler .status .message').hide();
          $('.netscaler .status').show();
          $('.netscaler .status .processing').fadeIn();
          netscaler_config_save = setInterval(function(){
            sec=parseInt($('.netscaler .status .processing .loader-text span').html()); 
            if (sec != 0) {
              $('.netscaler .status .processing .loader-text span').html(sec-1);
            }
          },1000);
          netscaler_timeout = setTimeout(function() {
            var params = '';
            var inputs = $(".netscaler .iphone-toggle-buttons input");
            inputs.each(function(i, el) {
              if ($(el).is(':checked')) {
                var name = $(el).attr('name');
                var value = $(el).attr('id');
                if (params == '') {
                  params += '?'+name+'='+value
                } else {
                  params += '&'+name+'='+value
                }
              }
            });

            $.ajax('/netscaler_config'+params, {
              beforeSend: function(jqXHR, settings) {
                $('.netscaler .status').show();
                $('.netscaler .status .processing .loader-text').html("Updating config...");
                $('.netscaler .status .processing').fadeIn();
                $('.netscaler .status .message').hide();
              },
              success: function(data, textStatus, jqXHR) {
                //console.log(data);
                $('.netscaler .status .processing').fadeOut();
                $('.netscaler .status .message').html("Config saved...");
                $('.netscaler .status .message').fadeIn();
              },
              error: function(jqXHR, textStatus, errorThrown) {
                //console.log(jqXHR, textStatus, errorThrown);
                $('.netscaler .status .processing').fadeOut();
                $('.netscaler .status .message').html("Error: "+errorThrown);
                $('.netscaler .status .message').fadeIn();
              },
              complete: function(jqXHR, textStatus) {
                setTimeout(function() {
                  $('.netscaler .status .message').fadeOut();
                }, 5000)
              }
            });
          }, save_in*1000);
        });

        // load generator config change
        var loader_timeout;
        var loader_config_save;
        $(".loader .iphone-toggle-buttons input").on('change', function(e) {
          clearTimeout(loader_timeout);
          clearTimeout(loader_config_save);
          $('.loader .status .processing .loader-text').html("Saving in <span>"+save_in+"</span>...");
          $('.loader .status .message').hide();
          $('.loader .status').show();
          $('.loader .status .processing').fadeIn();
          loader_config_save = setInterval(function(){
            sec=parseInt($('.loader .status .processing .loader-text span').html()); 
            if (sec != 0) {
              $('.loader .status .processing .loader-text span').html(sec-1);
            }
          },1000);
          loader_timeout = setTimeout(function() {
            var params = '';
            var inputs = $(".loader .iphone-toggle-buttons input");
            inputs.each(function(i, el) {
              if ($(el).is(':checked')) {
                var name = $(el).attr('name');
                var value = $(el).attr('id');
                if (params == '') {
                  params += '?'+name+'='+value
                } else {
                  params += '&'+name+'='+value
                }
              }
            });

            $.ajax('/loader_config'+params, {
              beforeSend: function(jqXHR, settings) {
                $('.loader .status').show();
                $('.loader .status .processing .loader-text').html("Updating config...");
                $('.loader .status .processing').fadeIn();
                $('.loader .status .message').hide();
              },
              success: function(data, textStatus, jqXHR) {
                //console.log(data);
                $('.loader .status .processing').fadeOut();
                $('.loader .status .message').html("Config saved...");
                $('.loader .status .message').fadeIn();
              },
              error: function(jqXHR, textStatus, errorThrown) {
                //console.log(jqXHR, textStatus, errorThrown);
                $('.loader .status .processing').fadeOut();
                $('.loader .status .message').html("Error: "+errorThrown);
                $('.loader .status .message').fadeIn();
              },
              complete: function(jqXHR, textStatus) {
                setTimeout(function() {
                  $('.loader .status .message').fadeOut();
                }, 5000)
              }
            });
          }, save_in*1000);
        });

      });
    </script>
	</head>
	<body>
    <div id="wrapper">

      <div id="content">
        <div class="section-header">Control Panel</div>
        Understand the correlation between different Netscaler configurations and your AWS resource usage.
      </div>

      <div id="controls">
        <div class="netscaler left">
          <div class="section-header">Netscaler</div>
          <div class="control-desc">
            Modify how the NetScaler delivers the content.
          </div>
          <div class="iphone-toggle-buttons">
            <ul>
              <li><label for="ns_profile_1">
                <input type="radio" name="ns_profile_group" id="ns_profile_1" checked="checked" />
                <span>Profile 1</span></label><span class="toggle-label">Basic config</span></li>
              <li><label for="ns_profile_2"><input type="radio" name="ns_profile_group" id="ns_profile_2" />
                <span>Profile 2</span></label><span class="toggle-label">With Caching</span></li>
              <li><label for="ns_profile_3"><input type="radio" name="ns_profile_group" id="ns_profile_3" />
                <span>Profile 3</span></label><span class="toggle-label">With Caching and Compression</span></li>
              <li class="status">
                <div class="processing"><span class="loader">&nbsp;</span><span class="loader-text">Updating config...</span></div>
                <div class="message"></div>
              </li>
            </ul>
          </div>
          <div class="control-footer">Go to the <a href="/netscaler_redirect">Netscaler Config</a> or <a href="/netscaler_redirect">Action Analytics</a></div>
        </div>
        <div class="loader right">
          <div class="section-header">Load Generator</div>
          <div class="control-desc">
            Modify how the load is generated.
          </div>
          <div class="iphone-toggle-buttons">
            <ul class="lg-profile-group">
              <li><label for="lg_profile_1">
                <input type="radio" name="lg_profile_group" id="lg_profile_1" checked="checked" />
                <span>Profile 1</span></label><span class="toggle-label">Unmodified traffic</span></li>
              <li><label for="lg_profile_2"><input type="radio" name="lg_profile_group" id="lg_profile_2" />
                <span>Profile 2</span></label><span class="toggle-label">Add latency and packet loss</span></li>
              <li><label for="lg_profile_3"><input type="radio" name="lg_profile_group" id="lg_profile_3" />
                <span>Profile 3</span></label><span class="toggle-label">Add jitter, latency and packet loss</span></li>
            </ul>
            <ul class="lg-load-group">
              <li><label for="lg_load_1">
                <input type="radio" name="lg_load_group" id="lg_load_1" checked="checked" />
                <span>Profile 1</span></label><span class="toggle-label">~50 requests/minute</span></li>
              <li><label for="lg_load_2"><input type="radio" name="lg_load_group" id="lg_load_2" />
                <span>Profile 2</span></label><span class="toggle-label">~500 requests/minute</span></li>
            </ul>
            <ul>
              <li class="status">
                <div class="processing"><span class="loader">&nbsp;</span><span class="loader-text">Updating config...</span></div>
                <div class="message"></div>
              </li>
            </ul>
          </div>
        </div>
        <div class="clear"> </div>
        <div class="section-footer">It will take a few minutes for the graphs to reflect config changes.</div>
      </div>
      

      <div id="graphs">
        <div class="section-header">AWS Resource Usage</div>
        <div class="refresh-wrapper">refreshing in <span class="refresh-in">60</span></div>
        <div class="left">
          <div id="cpu_utilization" style="width: 500px; height: 300px;"></div>
          <div id="mem_utilization" style="width: 500px; height: 300px;"></div>
        </div>
        <div class="right">
          <div id="network_in" style="width: 500px; height: 300px;"></div>
          <div id="network_out" style="width: 500px; height: 300px;"></div>
        </div>
        <div class="clear"> </div>
      </div>

    </div>
  </body>
</html>
            