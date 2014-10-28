xquery version "1.0-ml";

module namespace ext = "http://marklogic.com/rest-api/resource/ctakes-markup";

import module namespace ctakes = "http://marklogic.com/demo/ontology/ctakes-markup"
  at "/lib/ctakes.xqy";
import module namespace normalize = "http://marklogic.com/demo/ontology/normalize" at "/lib/normalize.xqy";


declare namespace roxy = "http://marklogic.com/roxy";
declare namespace rapi = "http://marklogic.com/rest-api";

declare option xdmp:mapping "false";

(:
 :)
declare
%rapi:transaction-mode("query")
function ext:post(
    $context as map:map,
    $params  as map:map,
    $input   as document-node()*
) as document-node()*
{
  let $enriched-text := ctakes:enrich-text($input)
  return (
    map:put($context, "output-types", "application/xml"),
    xdmp:set-response-code(200, "OK"),
    document {
      normalize:normalize($enriched-text)
    }
  )
};
