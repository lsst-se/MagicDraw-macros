##
#This was a test macro used to test the HTML parser macros.
##

require 'java'

Application = com.nomagic.magicdraw.core.Application
ModelHelper = com.nomagic.uml2.ext.jmi.helpers.ModelHelper
PrintWriter = java.io.PrintWriter

pw = PrintWriter.new("C:/Users/Tim/Desktop/output.txt","UTF-8");
string = ModelHelper.getComment(Application.getInstance().getProject().getBrowser().getContainmentTree().getSelectedNode().getUserObject());

pw.println('-----------------------Original-------------------------------');
pw.println(string);
pw.println('--------------------------------------------------------------');
pw.println('');

if(string.index('<b>Specification') == nil)
	pw.println('----------------------Discussion------------------------------');
	pw.println(string);
	pw.println('--------------------------------------------------------------');
	pw.println('');
elsif(string.index('<b>Discussion') == nil)
	pw.println('---------------------Specification----------------------------');
	pw.println(string);
	pw.println('--------------------------------------------------------------');
	pw.println('');
else
	pw.println('---------------------Specification----------------------------');
	pw.println('<html><pre>' + string[string.index('<b>Specification')..(string.index('<b>Discussion')-1)].strip + '</pre></html>');
	pw.println('--------------------------------------------------------------');
	pw.println('');
	pw.println('----------------------Discussion------------------------------');
	pw.println(string.gsub(string[string.index('<b>Specification')..(string.index('<b>Discussion')-1)],''));
	pw.println('--------------------------------------------------------------');
	pw.println('');
end
pw.close();