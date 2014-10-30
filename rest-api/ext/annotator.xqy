xquery version "1.0-ml";

module namespace ext = "http://marklogic.com/rest-api/resource/annotator";

import module namespace ann = "http://marklogic.com/demo/ontology/annotator" at "/lib/custom-annotator.xqy";
import module namespace normalize = "http://marklogic.com/demo/ontology/normalize" at "/lib/normalize.xqy";

declare namespace roxy = "http://marklogic.com/roxy";
declare namespace rapi = "http://marklogic.com/rest-api";

declare option xdmp:mapping "false";

(:
 : To add parameters to the functions, specify them in the params annotations.
 : Example
 :   declare %roxy:params("uri=xs:string", "priority=xs:int") ext:get(...)
 : This means that the get function will take two parameters, a string and an int.
 :)


(:
 :
 :)
declare
%roxy:params("input-type=xs:string?","mark-up=xs:boolean?")
%rapi:transaction-mode("query")
function ext:post(
    $context as map:map,
    $params  as map:map,
    $input   as document-node()*
) as document-node()*
{
  map:put($context, "output-types", "application/xml"),
  xdmp:set-response-code(200, "OK"),
  let $input-type := map:get($params, "input-type")
  let $mark-up := fn:boolean(map:get($params, "mark-up"))
  let $exclude := "qualifier value"
  return
    document {
      normalize:normalize(ann:annotate($input, $mark-up, $input-type, $exclude))
    }
};
