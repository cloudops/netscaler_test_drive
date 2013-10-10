<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
    <title>Control Panel</title>
    <script src="/static/js/jquery-1.10.2.min.js"></script>
    <script type="text/javascript">
		$(function() {
			document.form1.submit();
		});
	</script>
	</head>
<body>
<form name="form1" action="http://{{ns_host}}/login/do_login" method="post" autocomplete="off" style="display:none;">
	<input type="text" id="username" name="username" value="{{ns_user}}"></td>
	<input type="password" name="password" value="{{ns_pass}}">
	<select name="deployment_type" id="deploymenttypeid" size="1">
		<option value="neo" selected="">NetScaler ADC</option> 
		<option value="agee">NetScaler Gateway</option> 
		<option value="xm">XenMobile MDM</option> 
		<option value="cb">CloudBridge Connector</option> 
	</select>
	<select name="startin" id="appid" size="1">
		<option value="def" selected="">Default</option> 
		<option value="st">Dashboard</option> 
		<option value="neo">Configuration</option> 
		<option value="rep">Reporting</option> 
		<option value="doc">Documentation</option> 
		<option value="dw">Downloads</option> 
	</select>
	<input type="text" value="30" name="timeout">
    <select name="unit">
		<option value="Minutes">Minutes</option>
		<option value="Hours">Hours</option>
		<option value="Days">Days</option>
	</select>
	<select name="jvm_memory">
		<option value="system_default" title="Select this option to take Java memory settings from Java control panel.">System default</option>
		<option value="128M" title="Select this option if your local system memory is 512M">128M</option>
		<option value="256M" title="Select this option if your local system memory is 1G" selected="">256M</option>
		<option value="512M" title="Select this option if your local system memory is 2G">512M</option>
		<option value="1024M" title="Select this option if your local system memory is 4G">1024M</option>
	</select>
	<input type="hidden" name="url" value="/menu/neo">
	<input type="hidden" name="timezone_offset" value="">
	<input type="submit" value="Login" class="login_button">
</form>
</body>
</html>