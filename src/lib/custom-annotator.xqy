xquery version "1.0-ml";

module namespace ann = "http://marklogic.com/demo/ontology/annotator";
import module namespace functx = "http://www.functx.com" at
  "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

declare namespace roxy = "http://marklogic.com/roxy";
declare namespace rapi = "http://marklogic.com/rest-api";
declare namespace e    = "http://marklogic.com/entity";
declare namespace ont  = "http://marklogic.com/demo/ontology";

declare option xdmp:mapping "false";

(:
 : To add parameters to the functions, specify them in the params annotations.
 : Example
 :   declare %roxy:params("uri=xs:string", "priority=xs:int") ann:get(...)
 : This means that the get function will take two parameters, a string and an int.
 :)


(:
 :
 :)
declare
function ann:annotate(
    $input   as document-node()*,
    $mark-up as xs:boolean,
    $input-type as xs:string?
) as node()*
{
  for $i in $input
  let $in :=
    if ($i instance of document-node(element()))
    then $i
    else
      element doc {
        if ($input-type eq "admission-note")
        then
          ann:admission-note-transform($i)
        else
          fn:string($i)
      }
  let $reverse-query := cts:reverse-query($in)
  let $annotation-query :=
    cts:and-query((
      $reverse-query,
      cts:element-query(xs:QName("ont:reverse-query"),cts:and-query(()))
    ))
  let $matches-size := xdmp:estimate(cts:search(fn:collection()/ont:concept,$annotation-query))
  let $matches := cts:search(fn:collection()/ont:concept,$annotation-query,"unfiltered")
  let $matching-reverse-queries := $matches/ont:reverse-query
  return
      element ont:result {
        element ont:meta{
          element ont:match-count{$matches-size},
          ann:all-found-in-doc($in, $matching-reverse-queries)
        },
        if ($mark-up)
        then
          ann:markup-doc($in, $matching-reverse-queries)
        else
          $in
      }
};

declare
%private
function ann:all-found-in-doc(
    $input   as document-node()*,
    $matches as element(ont:reverse-query)*
) as element()*
{
  let $node-annotations := map:map()
  return (
    for $match in $matches
    return
      cts:walk(
        $input,
        cts:or-query((
          $match/cts:* ! cts:query(.)
        )),
        (: deal with overlap with help from
          https://help.marklogic.com/Knowledgebase/Article/View/132/0/ctshighlight-with-overlapping-matches :)
        if (fn:count($cts:queries) eq 1 or (every $q in $cts:queries satisfies ann:matches-entire-text($q,$cts:text)))
        then
          let $matching-q :=
            ann:select-appropriate-match($cts:text,$match,$cts:queries)
          let $concept := fn:root($matching-q)/ont:concept
          let $pref-label := fn:normalize-space($concept/ont:label)
          let $attributes := $concept/ont:notation/@*
          let $path := xdmp:path($cts:node)
          return
            cts:walk(
              element t {$cts:node},
              cts:query($matching-q),
              (
                let $annotation :=
                  element ont:notation{
                    $attributes,
                    if ($pref-label ne '') then
                      attribute ont:pref-label{$pref-label}
                    else (),
                    attribute ont:path{$path},
                    attribute ont:start{$cts:start},
                    attribute ont:length {fn:string-length($cts:text)},
                    $cts:text
                  }
                return
                map:put(
                  $node-annotations,
                  $path,
                  (
                    map:get($node-annotations, $path)[fn:not(fn:deep-equal(.,$annotation))],
                    $annotation
                  )
                ),
                xdmp:set($cts:action,"skip")
              )
            )
          else
            xdmp:set($cts:action, "continue")

      ),
    for $path in map:keys($node-annotations)
    order by $path
    return element ont:section {
      attribute ont:path {$path},
      for $ann in map:get($node-annotations, $path)
      order by $ann/@ont:start cast as xs:integer
      return $ann
    }
  )
};

declare
%private
function ann:markup-doc(
    $input   as document-node()*,
    $matches as element(ont:reverse-query)*
) as document-node()*
{
  if (fn:exists($matches))
  then
    cts:highlight(
      $input,
      cts:or-query((
        $matches/cts:* ! cts:query(.)
      )),
      (: deal with overlap with help from
        https://help.marklogic.com/Knowledgebase/Article/View/132/0/ctshighlight-with-overlapping-matches :)
      if (fn:count($cts:queries) eq 1 or (every $q in $cts:queries satisfies ann:matches-entire-text($q,$cts:text)))
      then
        let $matching-q :=
          ann:select-appropriate-match($cts:text,$matches,$cts:queries)
        let $concept := fn:root($matching-q)/ont:concept
        let $pref-label := fn:normalize-space($concept/ont:label)
        let $iri := $concept/ont:notation/@iri
        let $type := $concept/ont:notation/@type
        let $attributes := $concept/ont:notation/@* except ($iri, $type)
        return
          element e:entity {
            attribute id {sem:uuid-string()},
            $attributes,
            $iri ! attribute object { fn:string(.) },
            $type ! attribute predicate { "http://marklogic.com/demo/ontology/custom/mention#" || fn:replace(.,"\s+","-") },
            if ($pref-label ne '') then
              attribute ont:pref-label{$pref-label}
            else (),
            ann:matching-text($cts:node, $matching-q)
          }
      else
        xdmp:set($cts:action, "continue")

    )
  else
    $input
};
(: determine the appropriate item that caused a cts:query to match :)
declare
%private
function ann:select-appropriate-match(
  $text as xs:string,
  $all-matching-reverse-queries as element(ont:reverse-query)*,
  $matching-queries as cts:query*)
 as element(*,cts:query)? {
  let $most-accurate-query :=
        (
        let $lower-case-text := fn:lower-case($text)
        for $query as xs:string in ($matching-queries ! cts:word-query-text(.))
        let $match-level :=
          if ($query eq $text) then 0
          else if (fn:lower-case($query) eq $lower-case-text) then 1
          else 2
        order by $match-level ascending, fn:string-length($query) descending
        return $query
        )[1]
  let $query-for-query := cts:element-value-query(xs:QName("cts:text"),$most-accurate-query,"exact")
  let $matching-doc := (($all-matching-reverse-queries[cts:contains(.,$query-for-query)])[1]/cts:word-query[cts:text = $most-accurate-query])[1]
  return $matching-doc
};

declare
%private
function ann:matching-text(
  $node as node()?,
  $matching-q as element(*,cts:query)
) {
  cts:walk(
    element t {$node},
    cts:query($matching-q),
    (
      $cts:text,
      xdmp:set($cts:action,"skip")
    )
  )
};

declare
%private
function ann:matches-entire-text(
  $q as cts:query,
  $matching-text as xs:string)
 as xs:boolean {
  $matching-text = cts:walk(element t {$matching-text},$q,$cts:text)
};

declare variable $admission-headers as xs:string+ := (
    $chief-complaint-headers,
    $present-illness-headers,
    $review-systems-headers,
    $allergies-headers,
    $medications-headers,
    $past-medical-history-headers,
    $past-surgical-history-headers,
    $family-history-headers,
    $social-history-headers
  );

declare variable $chief-complaint-headers as xs:string+ := (
    "cc",
    "chief complaint"
  );
declare variable $present-illness-headers as xs:string+ := (
    "hpi",
    "history of present illness"
  );

declare variable $review-systems-headers as xs:string+ := (
    "ros",
    "review of systems"
  );

declare variable $allergies-headers as xs:string+ := (
    "allergies"
  );

declare variable $medications-headers as xs:string+ := (
    "medications"
  );

declare variable $past-medical-history-headers as xs:string+ := (
    "pmh",
    "past medical history"
  );

declare variable $past-surgical-history-headers as xs:string+ := (
    "psh",
    "past surgical history",
    "psurghx"
  );

declare variable $family-history-headers as xs:string+ := (
    "fh",
    "family history",
    "famhx"
  );

declare variable $social-history-headers as xs:string+ := (
    "sh",
    "social history",
    "sochx"
  );

declare
%private
function ann:admission-note-transform(
  $note as xs:string
) {
  ann:admission-note-dispatch(
    fn:analyze-string(
      $note,
      "^("||
        fn:string-join(
          $admission-headers ! functx:escape-for-regex(.),
          "|"
        )
      ||").*?(^[\s]*$)",
      "smi"
    )
  )
};


declare
%private
function ann:admission-note-dispatch(
  $node as node()
) {
  for $n in $node/node()
  return ann:admission-note-process($n)
};

declare
%private
function ann:admission-note-process(
  $node as node()
) {
  typeswitch($node)
  case element(fn:match) return
    element {ann:section-name($node/fn:group[1])} {
      fn:string($node)
    }
  case element() return
    ann:admission-note-dispatch($node)
  default return
    $node
};

declare
%private
function ann:section-name(
  $section as xs:string
) as xs:string {
  let $section := fn:lower-case($section)
  return
  switch(fn:true())
  case $section = $chief-complaint-headers return
    "chief-complaint"
  case $section = $present-illness-headers return
    "present-illness"
  case $section = $review-systems-headers return
    "review-of-systems"
  case $section = $allergies-headers return
    "allergies"
  case $section = $medications-headers return
    "medications"
  case $section = $past-medical-history-headers return
    "medical-history"
  case $section = $past-surgical-history-headers return
    "surgical-history"
  case $section = $family-history-headers return
    "family-history"
  case $section = $social-history-headers return
    "social-history"
  default return
    "section"
};
