xquery version "1.0-ml";

module namespace ctakes = "http://marklogic.com/demo/ontology/ctakes-markup";

import module namespace functx = "http://www.functx.com"
  at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace mem = "http://maxdewpoint.blogspot.com/memory-operations"
  at "/lib/mem-op/memory-operations.xqy";
import module namespace node-op = "http://maxdewpoint.blogspot.com/node-operations"
  at "/lib/mem-op/node-operations.xqy";

declare namespace e = "http://marklogic.com/entity";

declare option xdmp:mapping "false";

(: BEGIN enrichment section :)
declare variable $DEBUG := fn:false();

declare variable $BEGINS := ();
declare variable $ENDS := ();
declare variable $BEGIN-TAGS := ();
declare variable $END-TAGS := ();

declare variable $CROSSERS := ();


declare function ctakes:make-local-name($str as xs:string) as xs:string
{
  fn:lower-case(fn:replace($str, "\W+", "-"))
};


declare function ctakes:wrap-token-with-element($token as xs:string, $ename as xs:string)
  as xs:string
{
  fn:concat("<", $ename, ">", $token, "</", $ename, ">")
};

declare function ctakes:start-tag($ename as xs:string, $attributes as xs:string*)
  as xs:string
{
  fn:string-join(("<e:", $ename,
    for $attribute in $attributes
    return (" ", $attribute),
    ">"), "")
};

declare function ctakes:end-tag($ename as xs:string)
  as xs:string
{
  fn:concat("&lt;/e:", $ename, "&gt;")
};

declare function ctakes:sentence-attribute($thing as element(), $cas as element(CAS))
  as xs:string?
{
  let $begin := fn:number($thing/@begin)
  let $end := fn:number($thing/@end)
  let $sentence-number := fn:string(fn:head($cas/org.apache.ctakes.typesystem.type.textspan.Sentence[@begin le $begin and @end ge $end])/@sentenceNumber)
  return
    ctakes:attribute-if-exists('sentence', $sentence-number)
};

declare function ctakes:attribute-if-exists($name as xs:string, $value as xs:string?)
  as xs:string?
{
  if (fn:exists($value[. ne ''])) then
    fn:concat(fn:lower-case(fn:replace($name, "([A-Z])", "-$1")), "=&quot;", $value, "&quot;")
  else
    ()
};

declare function ctakes:crosses($begin as xs:integer, $end as xs:integer, $e as element())
  as xs:boolean
{
  if (fn:empty($BEGINS)) then
    fn:false()
  else
    let $count := fn:count($BEGINS)
    let $crosses :=
      some $i in (1 to $count) satisfies
      (
        let $begin2 := $BEGINS[$i]
        let $end2 := $ENDS[$i]
        return
          ($begin < $begin2 and $end > $begin2 and $end < $end2) or
          ($begin > $begin2 and $begin < $end2 and $end > $end2) or
          ($begin eq $begin2 and $end eq $end2)
      )

    let $_ :=
      if ($crosses) then
        xdmp:set($CROSSERS, ($CROSSERS, $e))
      else
        ()
    return $crosses
};

declare function ctakes:add-to-sequences($begin as xs:integer, $end as xs:integer,
  $begin-tag as xs:string, $end-tag as xs:string, $e as element())
  as empty-sequence()
{
  if (ctakes:crosses($begin, $end, $e)) then
    ()
  else
    (
      xdmp:set($BEGINS, ($BEGINS, $begin)),
      xdmp:set($ENDS, ($ENDS, $end)),
      xdmp:set($BEGIN-TAGS, ($BEGIN-TAGS, $begin-tag)),
      xdmp:set($END-TAGS, ($END-TAGS, $end-tag))
    )
};

declare function ctakes:process-stuff(
  $things,
  $cas as element(CAS),
  $element-name as xs:string)
{
  let $log := if ($DEBUG) then xdmp:log($element-name || " count: " || fn:count($things)) else ()
  for $thing in $things
  let $ont-concept-id := fn:string($thing/@_ref_ontologyConceptArr)
  let $ont-concept := fn:head($cas/uima.cas.FSArray[@_id eq $ont-concept-id])
  let $related-ids := $ont-concept/i ! fn:string(.)
  let $related-items := if (fn:exists($related-ids)) then $cas/*[@_id = $related-ids] else (<nil/>)
  for $related-item in $related-items
  let $attributes :=
  (
    ctakes:sentence-attribute($thing, $cas),
    ctakes:attribute-if-exists('id', $thing/@_id),
    ctakes:attribute-if-exists('subject', $thing/@subject),
    (: search for details :)
    if (fn:exists($related-item[@codingScheme][@code]))
    then
      ctakes:attribute-if-exists('object', map:get($IRI-MAPPING, fn:string($related-item/@codingScheme)) || fn:string($related-item/@code))
    else
      (),
    let $type :=
      ctakes:camel-case-to-hyphen(fn:replace($element-name, "(.*)(Mention|Annotation)", "$1"))
    return
      ctakes:attribute-if-exists("predicate", "http://marklogic.com/demo/ontology/ctakes/mention#"||$type)
  )
  let $markup-name := "entity"
  let $existing := fn:index-of($BEGINS,$thing/xs:integer(@begin))
  where fn:empty($existing)
  return
      ctakes:add-to-sequences(
        $thing/xs:integer(@begin),
        $thing/xs:integer(@end),
        ctakes:start-tag($markup-name, $attributes),
        ctakes:end-tag($markup-name),
        $thing
      )
};

declare function ctakes:init()
  as empty-sequence()
{
  xdmp:set($BEGINS, ()),
  xdmp:set($ENDS, ()),
  xdmp:set($BEGIN-TAGS, ()),
  xdmp:set($END-TAGS, ()),
  xdmp:set($CROSSERS, ())
};

declare function ctakes:process-all($cas)
  as empty-sequence()
{
  ctakes:init(),
  for $e in $cas/*[@subject][@begin][@end]
  return
    ctakes:process-stuff($e, $cas, fn:replace(fn:local-name($e), "^.*\.([^.]+)$", "$1"))
};


declare function ctakes:log-offsets($label, $seq)
{
  xdmp:log(
    fn:concat($label, ": ",
      fn:string-join(
        for $s in $seq
        return fn:string($s)
        , ",")
    )
  )
};

declare function ctakes:transform($cas as element(CAS))
  as element(root)
{
  let $text := $cas/uima.cas.Sofa/fn:string(@sofaString)
  let $_ := ctakes:process-all($cas)

  let $str :=
      fn:concat(
        "&lt;doc xmlns:e='http://marklogic.com/entity'&gt;",
        ctakes:markup($text, $BEGINS, $ENDS, $BEGIN-TAGS, $END-TAGS),
        "&lt;/doc&gt;"
      )

  let $doc :=
    try
    {
      xdmp:unquote($str)
    }
    catch ($e)
    {
      xdmp:log($str),
      xdmp:rethrow()
    }

  return
    <root>
    {
      $doc,
      <crossing-elements>
      {
        $CROSSERS
      }
      </crossing-elements>
    }
    </root>
};

declare function ctakes:markup($text, $begins, $ends, $begin-tags, $end-tags)
{
  if (fn:empty($begins)) then
    fn:replace($text, "&amp;", "&amp;amp;")
  else
    let $begin := fn:head($begins)
    let $end := fn:head($ends)
    let $begin-tag := fn:head($begin-tags)
    let $end-tag := fn:head($end-tags)
    let $b-length := fn:string-length($begin-tag)
    let $e-length := fn:string-length($end-tag)

    let $_ :=
      if ($DEBUG) then
        (
          ctakes:log-offsets("begins", $begins),
          ctakes:log-offsets("ends", $ends)
        )
      else
        ()

    let $text := functx:insert-string($text, $end-tag, $end + 1)
    let $text := functx:insert-string($text, $begin-tag, $begin + 1)

    let $new-begins := fn:tail($begins)
    let $new-ends := fn:tail($ends)

    let $begins-temp := $new-begins

    let $new-begins :=
      for $b2 at $i in $new-begins
      return
        if ($b2 >= $end) then
          $b2 + $b-length + $e-length
        (: if the begin offset is the same as the current one, then
           compare the length of the markup area. if the difference in the offsets
           is greater than the current difference, then the tags need to go outside
           the current ones ($b2) else inside ($b2 + $b-length) :)
        else if ($b2 = $begin) then
          if ($new-ends[$i] - $b2 > $end - $begin) then
            $b2
          else
            $b2 + $b-length
        else if ($b2 > $begin) then
          $b2 + $b-length
        else
          $b2

    let $new-ends :=
      for $e2 at $i in $new-ends
      return
        if ($e2 > $end) then
          $e2 + $b-length + $e-length
        (: see comment above :)
        else if ($e2 = $end) then
          if ($e2 - $begins-temp[$i] > $end - $begin) then
            $e2 + $b-length + $e-length
          else
            $e2 + $b-length
        else if ($e2 > $begin) then
          $e2 + $b-length
        else
          $e2

    return ctakes:markup($text, $new-begins, $new-ends, fn:tail($begin-tags), fn:tail($end-tags))
};

declare function ctakes:sanitize-xml($txt)
{
  let $txt := fn:replace($txt, "<", "&amp;lt;")
  let $txt := fn:replace($txt, ">", "&amp;gt;")
  let $txt := fn:replace($txt, "&amp;", "&amp;amp;")
  return
    $txt
};


declare function ctakes:enrich-text(
  $txt as xs:string)
{
  let $url := "http://localhost:8080/enrich"
  let $txt := ctakes:sanitize-xml($txt)
  let $response := xdmp:http-post($url, <options xmlns="xdmp:http"><data>{$txt}</data><timeout>99999999</timeout></options>)
  let $cas := $response[2]/CAS
  return
    ctakes:transform($cas)
};

declare function ctakes:camel-case-to-hyphen(
  $arg as xs:string?)
{
  fn:replace(fn:lower-case(fn:replace($arg,"([A-Z])","-$1")),"^\-","")
};

declare variable $IRI-MAPPING :=
  map:new((
    map:entry("RXNORM",
      "http://purl.bioontology.org/ontology/RXNORM/"
    ),
    map:entry("SNOMED",
      "http://snomed.info/id/"
    )
  ));
(: END enrichment section :)
