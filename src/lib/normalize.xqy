xquery version "1.0-ml";

module namespace normalize = "http://marklogic.com/demo/ontology/normalize";

import module namespace mem = "http://maxdewpoint.blogspot.com/memory-operations"
  at "/lib/mem-op/memory-operations.xqy";
import module namespace node-op = "http://maxdewpoint.blogspot.com/node-operations"
  at "/lib/mem-op/node-operations.xqy";

declare namespace e = "http://marklogic.com/entity";

declare function normalize:normalize(
  $content as node())
{
  let $tid as xs:string := mem:copy($content)
  let $entities := node-op:outermost($content//e:entity)
  let $_normalize as empty-sequence() :=
    (
      mem:transform(
        $tid,
        $entities,
        function ($n) {
          element {fn:node-name($n)} {
            $n/@*,
            $n/node() ! (text {fn:string(.)})
          }
        }
      ),
      mem:insert-child($tid, $content,
        element suggested-triples {
          for $e in $entities[@subject][@predicate][@object]
          let $has-object := fn:exists($e/@object)
          let $subject-id :=
            if ($has-object) then
              fn:string($e/@id)
            else
              normalize:related-id($e)
          where fn:exists($subject-id)
          return
            sem:triple(
              sem:iri(fn:string($e/@subject) || '#' || $subject-id),
              sem:iri(fn:string($e/@predicate)),
              if ($has-object) then
                sem:iri(fn:string($e/@object))
              else
                fn:string($e)
            )
        }
      )
    )
  return mem:execute($tid)
};

declare function normalize:related-id(
  $entity as element(e:entity)) as xs:string?
{
  let $sentence := $entity/@sentence
  let $sentence-entities := fn:root($entity)//e:entity[@sentence eq $sentence][@object] except $entity
  return
    (for $e in $sentence-entities
     let $first := fn:head($e|$entity)
     let $last := fn:tail($e|$entity)
     stable order by fn:count($first/following-sibling::e:entity except $last/(.|following-sibling::e:entity))
     return $e)[1]/@id
};
