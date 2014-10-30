
./ml local bootstrap  
./ml local deploy modules  

Download SNOMED_CT data at http://www.nlm.nih.gov/research/umls/Snomed/us_edition.html and unzip  
cd $PROJECT_HOME/scripts/snomed  
perl marklogic-snomed-xmlify.pl ~/Documents/healthcare-data/snomed/SnomedCT_Release_US1000124_20140301/RF2Release/Snapshot  
mlcp.sh import -host localhost -port 9061 -username admin -password admin -options_file snomed-xml-options.txt  
Download RXNORM data at http://www.nlm.nih.gov/research/umls/rxnorm/docs/rxnormfiles.html and unzip  
cd $PROJECT_HOME/scripts/rxnorm  
perl marklogic-rxnorm-xmlify.pl ~/Documents/healthcare-data/rxnorm/RxNorm_full_07072014  
mlcp.sh import -host localhost -port 9061 -username admin -password admin -options_file rxnorm-xml-options.txt  

Code:
```xquery
xquery version "1.0-ml";

import module namespace ann = "http://marklogic.com/demo/ontology/annotator" at "/lib/custom-annotator.xqy";
import module namespace normalize = "http://marklogic.com/demo/ontology/normalize" at "/lib/normalize.xqy";

declare namespace ont  = "http://marklogic.com/demo/ontology";

let $doc := document {element doc {"Dr. Nutritious
 
Medical Nutrition Therapy for Hyperlipidemia
Referral from: Julie Tester, RD, LD, CNSD
Phone contact: (555) 555-1212
Height: 144 cm Current Weight: 45 kg Date of current weight: 02-29-2001
Admit Weight: 53 kg BMI: 18 kg/m2
Diet: General
Daily Calorie needs (kcals): 1500 calories, assessed as HB + 20% for activity.
Daily Protein needs: 40 grams, assessed as 1.0 g/kg.
Pt has been on a 3-day calorie count and has had an average intake of 1100 calories.
She was instructed to drink 2-3 cans of liquid supplement to help promote weight gain.
She agrees with the plan and has my number for further assessment. May want a Resting
Metabolic Rate as well. She takes an aspirin a day for knee pain."}}
return (
    normalize:normalize(ann:annotate($doc, fn:true(),(),("qualifier value")))
  )
```

Output:
```xml
<ont:result xmlns:mem-op="http://maxdewpoint.blogspot.com/memory-operations" xmlns:ont="http://marklogic.com/demo/ontology">
  <ont:meta>
    <ont:match-count>43</ont:match-count>
    <ont:section ont:path="/doc/text()">
      <ont:notation subject="patient" code-schema="SNOMED" code="386373004" type="regime/therapy" iri="http://snomed.info/id/386373004" ont:pref-label="Nutrition therapy (regime/therapy)" ont:path="/doc/text()" ont:start="26" ont:length="17">Nutrition Therapy</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="384759009" type="observable entity" iri="http://snomed.info/id/384759009" ont:pref-label="Nutrition, function (observable entity)" ont:path="/doc/text()" ont:start="26" ont:length="9">Nutrition</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="277132007" type="procedure" iri="http://snomed.info/id/277132007" ont:pref-label="Therapeutic procedure (procedure)" ont:path="/doc/text()" ont:start="36" ont:length="7">Therapy</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="276239002" type="regime/therapy" iri="http://snomed.info/id/276239002" ont:pref-label="Therapy (regime/therapy)" ont:path="/doc/text()" ont:start="36" ont:length="7">Therapy</ont:notation>
      <ont:notation subject="patient" type="medication" code-schema="RXNORM" code="1023000" iri="http://purl.bioontology.org/ontology/RXNORM/1023000" ont:pref-label="Hyperlipemia" ont:path="/doc/text()" ont:start="48" ont:length="14">Hyperlipidemia</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="55822004" type="disorder" iri="http://snomed.info/id/55822004" ont:pref-label="Hyperlipidemia (disorder)" ont:path="/doc/text()" ont:start="48" ont:length="14">Hyperlipidemia</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="3457005" type="procedure" iri="http://snomed.info/id/3457005" ont:pref-label="Patient referral (procedure)" ont:path="/doc/text()" ont:start="63" ont:length="8">Referral</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="87717000" type="physical object" iri="http://snomed.info/id/87717000" ont:pref-label="Tester, device (physical object)" ont:path="/doc/text()" ont:start="84" ont:length="6">Tester</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="15874002" type="contextual qualifier" iri="http://snomed.info/id/15874002" ont:pref-label="Revised diagnosis (contextual qualifier) (qualifier value)" ont:path="/doc/text()" ont:start="92" ont:length="2">RD</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="46159000" type="contextual qualifier" iri="http://snomed.info/id/46159000" ont:pref-label="Laboratory diagnosis (contextual qualifier) (qualifier value)" ont:path="/doc/text()" ont:start="96" ont:length="2">LD</ont:notation>
      <ont:notation subject="patient" type="medication" code-schema="RXNORM" code="899742" iri="http://purl.bioontology.org/ontology/RXNORM/899742" ont:pref-label="date allergenic extract" ont:path="/doc/text()" ont:start="172" ont:length="4">Date</ont:notation>
      <ont:notation subject="patient" type="medication" code-schema="RXNORM" code="476222" iri="http://purl.bioontology.org/ontology/RXNORM/476222" ont:pref-label="Dates" ont:path="/doc/text()" ont:start="172" ont:length="4">Date</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="41829006" type="finding" iri="http://snomed.info/id/41829006" ont:pref-label="Dietary finding (finding)" ont:path="/doc/text()" ont:start="241" ont:length="4">Diet</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="38082009" type="substance" iri="http://snomed.info/id/38082009" ont:pref-label="Hemoglobin (substance)" ont:path="/doc/text()" ont:start="311" ont:length="2">HB</ont:notation>
      <ont:notation subject="patient" type="medication" code-schema="RXNORM" code="5202" iri="http://purl.bioontology.org/ontology/RXNORM/5202" ont:pref-label="Hemoglobin" ont:path="/doc/text()" ont:start="311" ont:length="2">HB</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="118582008" type="property" iri="http://snomed.info/id/118582008" ont:pref-label="Percent (property) (qualifier value)" ont:path="/doc/text()" ont:start="318" ont:length="1">%</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="257733005" type="observable entity" iri="http://snomed.info/id/257733005" ont:pref-label="Activity (observable entity)" ont:path="/doc/text()" ont:start="324" ont:length="8">activity</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="88878007" type="substance" iri="http://snomed.info/id/88878007" ont:pref-label="Protein (substance)" ont:path="/doc/text()" ont:start="340" ont:length="7">Protein</ont:notation>
      <ont:notation subject="patient" type="medication" code-schema="RXNORM" code="8859" iri="http://purl.bioontology.org/ontology/RXNORM/8859" ont:pref-label="Proteins" ont:path="/doc/text()" ont:start="340" ont:length="7">Protein</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="421426001" type="tumor staging" iri="http://snomed.info/id/421426001" ont:pref-label="Tumor staging descriptor a (tumor staging)" ont:path="/doc/text()" ont:start="402" ont:length="1">a</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="86933000" type="finding" iri="http://snomed.info/id/86933000" ont:pref-label="Heavy drinker (finding)" ont:path="/doc/text()" ont:start="494" ont:length="5">drink</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="25702006" type="disorder" iri="http://snomed.info/id/25702006" ont:pref-label="Alcohol intoxication (disorder)" ont:path="/doc/text()" ont:start="494" ont:length="5">drink</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="30953006" type="observable entity" iri="http://snomed.info/id/30953006" ont:pref-label="Drinking (observable entity)" ont:path="/doc/text()" ont:start="494" ont:length="5">drink</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="226465004" type="substance" iri="http://snomed.info/id/226465004" ont:pref-label="Drinks (substance)" ont:path="/doc/text()" ont:start="494" ont:length="5">drink</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="33463005" type="substance" iri="http://snomed.info/id/33463005" ont:pref-label="Liquid substance (substance)" ont:path="/doc/text()" ont:start="512" ont:length="6">liquid</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="264312008" type="finding" iri="http://snomed.info/id/264312008" ont:pref-label="Liquid (finding)" ont:path="/doc/text()" ont:start="512" ont:length="6">liquid</ont:notation>
      <ont:notation subject="patient" type="medication" code-schema="RXNORM" code="90230" iri="http://purl.bioontology.org/ontology/RXNORM/90230" ont:pref-label="Liquid" ont:path="/doc/text()" ont:start="512" ont:length="6">liquid</ont:notation>
      <ont:notation subject="patient" type="medication" code-schema="RXNORM" code="1246214" iri="http://purl.bioontology.org/ontology/RXNORM/1246214" ont:pref-label="Promote" ont:path="/doc/text()" ont:start="538" ont:length="7">promote</ont:notation>
      <ont:notation subject="patient" type="medication" code-schema="RXNORM" code="1024986" iri="http://purl.bioontology.org/ontology/RXNORM/1024986" ont:pref-label="Weight Gain" ont:path="/doc/text()" ont:start="546" ont:length="11">weight gain</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="8943002" type="finding" iri="http://snomed.info/id/8943002" ont:pref-label="Weight gain (finding)" ont:path="/doc/text()" ont:start="546" ont:length="11">weight gain</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="312011006" type="observable entity" iri="http://snomed.info/id/312011006" ont:pref-label="Cognitive function: planning (observable entity)" ont:path="/doc/text()" ont:start="579" ont:length="4">plan</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="410681005" type="property" iri="http://snomed.info/id/410681005" ont:pref-label="Count of entities (property) (qualifier value)" ont:path="/doc/text()" ont:start="595" ont:length="6">number</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="386053000" type="procedure" iri="http://snomed.info/id/386053000" ont:pref-label="Evaluation procedure (procedure)" ont:path="/doc/text()" ont:start="614" ont:length="10">assessment</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="258157001" type="observable entity" iri="http://snomed.info/id/258157001" ont:pref-label="Rest (observable entity)" ont:path="/doc/text()" ont:start="637" ont:length="7">Resting</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="387458008" type="substance" iri="http://snomed.info/id/387458008" ont:pref-label="Aspirin (substance)" ont:path="/doc/text()" ont:start="682" ont:length="7">aspirin</ont:notation>
      <ont:notation subject="patient" type="medication" code-schema="RXNORM" code="1191" iri="http://purl.bioontology.org/ontology/RXNORM/1191" ont:pref-label="Aspirin" ont:path="/doc/text()" ont:start="682" ont:length="7">aspirin</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="7947003" type="product" iri="http://snomed.info/id/7947003" ont:pref-label="Aspirin (product)" ont:path="/doc/text()" ont:start="682" ont:length="7">aspirin</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="30989003" type="finding" iri="http://snomed.info/id/30989003" ont:pref-label="Knee pain (finding)" ont:path="/doc/text()" ont:start="700" ont:length="9">knee pain</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="72696002" type="body structure" iri="http://snomed.info/id/72696002" ont:pref-label="Knee region structure (body structure)" ont:path="/doc/text()" ont:start="700" ont:length="4">knee</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="361291001" type="body structure" iri="http://snomed.info/id/361291001" ont:pref-label="Entire knee region (body structure)" ont:path="/doc/text()" ont:start="700" ont:length="4">knee</ont:notation>
      <ont:notation subject="patient" code-schema="SNOMED" code="22253000" type="finding" iri="http://snomed.info/id/22253000" ont:pref-label="Pain (finding)" ont:path="/doc/text()" ont:start="705" ont:length="4">pain</ont:notation>
      <ont:notation subject="patient" type="medication" code-schema="RXNORM" code="1021856" iri="http://purl.bioontology.org/ontology/RXNORM/1021856" ont:pref-label="Pain" ont:path="/doc/text()" ont:start="705" ont:length="4">pain</ont:notation>
    </ont:section>
  </ont:meta>
  <doc>Dr. Nutritious
 
Medical <e:entity id="6b7cbe86-9fd6-468a-925d-78111b769dc8" subject="patient" code-schema="SNOMED" code="386373004" object="http://snomed.info/id/386373004" predicate="http://marklogic.com/demo/ontology/custom/mention#regime/therapy" ont:pref-label="Nutrition therapy (regime/therapy)" xmlns:e="http://marklogic.com/entity">Nutrition Therapy</e:entity> for <e:entity id="705d97ed-6677-46e4-b6c0-6044858ae84e" subject="patient" code-schema="RXNORM" code="1023000" object="http://purl.bioontology.org/ontology/RXNORM/1023000" predicate="http://marklogic.com/demo/ontology/custom/mention#medication" ont:pref-label="Hyperlipemia" xmlns:e="http://marklogic.com/entity">Hyperlipidemia</e:entity>
<e:entity id="afa4b07f-a2e1-4db0-907f-a800f15e0746" subject="patient" code-schema="SNOMED" code="3457005" object="http://snomed.info/id/3457005" predicate="http://marklogic.com/demo/ontology/custom/mention#procedure" ont:pref-label="Patient referral (procedure)" xmlns:e="http://marklogic.com/entity">Referral</e:entity> from: Julie <e:entity id="0fa6e10c-3d36-476c-913e-3634e1b188ef" subject="patient" code-schema="SNOMED" code="87717000" object="http://snomed.info/id/87717000" predicate="http://marklogic.com/demo/ontology/custom/mention#physical-object" ont:pref-label="Tester, device (physical object)" xmlns:e="http://marklogic.com/entity">Tester</e:entity>, <e:entity id="bfa48765-ea57-447d-9799-4133734bd50a" subject="patient" code-schema="SNOMED" code="15874002" object="http://snomed.info/id/15874002" predicate="http://marklogic.com/demo/ontology/custom/mention#contextual-qualifier" ont:pref-label="Revised diagnosis (contextual qualifier) (qualifier value)" xmlns:e="http://marklogic.com/entity">RD</e:entity>, <e:entity id="4e11aefa-f4c3-496b-83e5-42c73494409f" subject="patient" code-schema="SNOMED" code="46159000" object="http://snomed.info/id/46159000" predicate="http://marklogic.com/demo/ontology/custom/mention#contextual-qualifier" ont:pref-label="Laboratory diagnosis (contextual qualifier) (qualifier value)" xmlns:e="http://marklogic.com/entity">LD</e:entity>, CNSD
Phone contact: (555) 555-1212
Height: 144 cm Current Weight: 45 kg <e:entity id="ff01fd25-8fa7-4e1e-b59d-f200f1aaecca" subject="patient" code-schema="RXNORM" code="899742" object="http://purl.bioontology.org/ontology/RXNORM/899742" predicate="http://marklogic.com/demo/ontology/custom/mention#medication" ont:pref-label="date allergenic extract" xmlns:e="http://marklogic.com/entity">Date</e:entity> of current weight: 02-29-2001
Admit Weight: 53 kg BMI: 18 kg/m2
<e:entity id="a123620f-5fa8-4460-9408-c031c7411326" subject="patient" code-schema="SNOMED" code="41829006" object="http://snomed.info/id/41829006" predicate="http://marklogic.com/demo/ontology/custom/mention#finding" ont:pref-label="Dietary finding (finding)" xmlns:e="http://marklogic.com/entity">Diet</e:entity>: General
Daily Calorie needs (kcals): 1500 calories, assessed as <e:entity id="586fdf22-b099-44e2-9f19-d1d3d022e69a" subject="patient" code-schema="SNOMED" code="38082009" object="http://snomed.info/id/38082009" predicate="http://marklogic.com/demo/ontology/custom/mention#substance" ont:pref-label="Hemoglobin (substance)" xmlns:e="http://marklogic.com/entity">HB</e:entity> + 20<e:entity id="50828033-4c50-4b66-9dce-5b40b9bbca41" subject="patient" code-schema="SNOMED" code="118582008" object="http://snomed.info/id/118582008" predicate="http://marklogic.com/demo/ontology/custom/mention#property" ont:pref-label="Percent (property) (qualifier value)" xmlns:e="http://marklogic.com/entity">%</e:entity> for <e:entity id="24020b8d-02dc-4e00-b74b-af3ba95f8ba1" subject="patient" code-schema="SNOMED" code="257733005" object="http://snomed.info/id/257733005" predicate="http://marklogic.com/demo/ontology/custom/mention#observable-entity" ont:pref-label="Activity (observable entity)" xmlns:e="http://marklogic.com/entity">activity</e:entity>.
Daily <e:entity id="dd51c28b-1173-4c2e-abde-d98f105a6a83" subject="patient" code-schema="SNOMED" code="88878007" object="http://snomed.info/id/88878007" predicate="http://marklogic.com/demo/ontology/custom/mention#substance" ont:pref-label="Protein (substance)" xmlns:e="http://marklogic.com/entity">Protein</e:entity> needs: 40 grams, assessed as 1.0 g/kg.
Pt has been on <e:entity id="934a2480-0465-4447-91b0-8192d0e5482f" subject="patient" code-schema="SNOMED" code="421426001" object="http://snomed.info/id/421426001" predicate="http://marklogic.com/demo/ontology/custom/mention#tumor-staging" ont:pref-label="Tumor staging descriptor a (tumor staging)" xmlns:e="http://marklogic.com/entity">a</e:entity> 3-day calorie count and has had an average intake of 1100 calories.
She was instructed to <e:entity id="922591b6-1e94-407f-a4d5-05ae69de3618" subject="patient" code-schema="SNOMED" code="30953006" object="http://snomed.info/id/30953006" predicate="http://marklogic.com/demo/ontology/custom/mention#observable-entity" ont:pref-label="Drinking (observable entity)" xmlns:e="http://marklogic.com/entity">drink</e:entity> 2-3 cans of <e:entity id="6e0de1d7-9a2c-4d43-8435-196275f4df1d" subject="patient" code-schema="SNOMED" code="33463005" object="http://snomed.info/id/33463005" predicate="http://marklogic.com/demo/ontology/custom/mention#substance" ont:pref-label="Liquid substance (substance)" xmlns:e="http://marklogic.com/entity">liquid</e:entity> supplement to help <e:entity id="b3913ac0-4a1d-45f4-afa4-cd30fa4c2fff" subject="patient" code-schema="RXNORM" code="1246214" object="http://purl.bioontology.org/ontology/RXNORM/1246214" predicate="http://marklogic.com/demo/ontology/custom/mention#medication" ont:pref-label="Promote" xmlns:e="http://marklogic.com/entity">promote</e:entity> <e:entity id="caeddee2-b7d4-4a78-bd39-9dcbad3c4ff3" subject="patient" code-schema="RXNORM" code="1024986" object="http://purl.bioontology.org/ontology/RXNORM/1024986" predicate="http://marklogic.com/demo/ontology/custom/mention#medication" ont:pref-label="Weight Gain" xmlns:e="http://marklogic.com/entity">weight gain</e:entity>.
She agrees with the <e:entity id="9a663294-b18f-4b68-847a-10984cfd9a37" subject="patient" code-schema="SNOMED" code="312011006" object="http://snomed.info/id/312011006" predicate="http://marklogic.com/demo/ontology/custom/mention#observable-entity" ont:pref-label="Cognitive function: planning (observable entity)" xmlns:e="http://marklogic.com/entity">plan</e:entity> and has my <e:entity id="ca912b33-1a4e-46dc-aa0f-b9b7b9e71645" subject="patient" code-schema="SNOMED" code="410681005" object="http://snomed.info/id/410681005" predicate="http://marklogic.com/demo/ontology/custom/mention#property" ont:pref-label="Count of entities (property) (qualifier value)" xmlns:e="http://marklogic.com/entity">number</e:entity> for further <e:entity id="b6c50038-4646-4ea2-bc8d-800b82666178" subject="patient" code-schema="SNOMED" code="386053000" object="http://snomed.info/id/386053000" predicate="http://marklogic.com/demo/ontology/custom/mention#procedure" ont:pref-label="Evaluation procedure (procedure)" xmlns:e="http://marklogic.com/entity">assessment</e:entity>. May want <e:entity id="3908591f-1d2b-4381-ae6a-a5bc815cd4f7" subject="patient" code-schema="SNOMED" code="421426001" object="http://snomed.info/id/421426001" predicate="http://marklogic.com/demo/ontology/custom/mention#tumor-staging" ont:pref-label="Tumor staging descriptor a (tumor staging)" xmlns:e="http://marklogic.com/entity">a</e:entity> <e:entity id="4ebdace9-c15a-4da4-bf60-73f3d0b119d9" subject="patient" code-schema="SNOMED" code="258157001" object="http://snomed.info/id/258157001" predicate="http://marklogic.com/demo/ontology/custom/mention#observable-entity" ont:pref-label="Rest (observable entity)" xmlns:e="http://marklogic.com/entity">Resting</e:entity>
Metabolic Rate as well. She takes an <e:entity id="b45d4354-7458-47e1-a924-56c4d22e8ee4" subject="patient" code-schema="RXNORM" code="1191" object="http://purl.bioontology.org/ontology/RXNORM/1191" predicate="http://marklogic.com/demo/ontology/custom/mention#medication" ont:pref-label="Aspirin" xmlns:e="http://marklogic.com/entity">aspirin</e:entity> <e:entity id="62bf69d9-7ef5-47ca-93b3-30d5b1389290" subject="patient" code-schema="SNOMED" code="421426001" object="http://snomed.info/id/421426001" predicate="http://marklogic.com/demo/ontology/custom/mention#tumor-staging" ont:pref-label="Tumor staging descriptor a (tumor staging)" xmlns:e="http://marklogic.com/entity">a</e:entity> day for <e:entity id="818543da-8fa2-4f4b-b8ff-49e3d84ac65e" subject="patient" code-schema="SNOMED" code="30989003" object="http://snomed.info/id/30989003" predicate="http://marklogic.com/demo/ontology/custom/mention#finding" ont:pref-label="Knee pain (finding)" xmlns:e="http://marklogic.com/entity">knee pain</e:entity>.</doc>
  <suggested-triples>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#6b7cbe86-9fd6-468a-925d-78111b769dc8</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#regime/therapy</sem:predicate>
      <sem:object>http://snomed.info/id/386373004</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#705d97ed-6677-46e4-b6c0-6044858ae84e</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#medication</sem:predicate>
      <sem:object>http://purl.bioontology.org/ontology/RXNORM/1023000</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#afa4b07f-a2e1-4db0-907f-a800f15e0746</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#procedure</sem:predicate>
      <sem:object>http://snomed.info/id/3457005</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#0fa6e10c-3d36-476c-913e-3634e1b188ef</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#physical-object</sem:predicate>
      <sem:object>http://snomed.info/id/87717000</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#bfa48765-ea57-447d-9799-4133734bd50a</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#contextual-qualifier</sem:predicate>
      <sem:object>http://snomed.info/id/15874002</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#4e11aefa-f4c3-496b-83e5-42c73494409f</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#contextual-qualifier</sem:predicate>
      <sem:object>http://snomed.info/id/46159000</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#ff01fd25-8fa7-4e1e-b59d-f200f1aaecca</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#medication</sem:predicate>
      <sem:object>http://purl.bioontology.org/ontology/RXNORM/899742</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#a123620f-5fa8-4460-9408-c031c7411326</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#finding</sem:predicate>
      <sem:object>http://snomed.info/id/41829006</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#586fdf22-b099-44e2-9f19-d1d3d022e69a</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#substance</sem:predicate>
      <sem:object>http://snomed.info/id/38082009</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#50828033-4c50-4b66-9dce-5b40b9bbca41</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#property</sem:predicate>
      <sem:object>http://snomed.info/id/118582008</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#24020b8d-02dc-4e00-b74b-af3ba95f8ba1</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#observable-entity</sem:predicate>
      <sem:object>http://snomed.info/id/257733005</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#dd51c28b-1173-4c2e-abde-d98f105a6a83</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#substance</sem:predicate>
      <sem:object>http://snomed.info/id/88878007</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#934a2480-0465-4447-91b0-8192d0e5482f</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#tumor-staging</sem:predicate>
      <sem:object>http://snomed.info/id/421426001</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#922591b6-1e94-407f-a4d5-05ae69de3618</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#observable-entity</sem:predicate>
      <sem:object>http://snomed.info/id/30953006</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#6e0de1d7-9a2c-4d43-8435-196275f4df1d</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#substance</sem:predicate>
      <sem:object>http://snomed.info/id/33463005</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#b3913ac0-4a1d-45f4-afa4-cd30fa4c2fff</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#medication</sem:predicate>
      <sem:object>http://purl.bioontology.org/ontology/RXNORM/1246214</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#caeddee2-b7d4-4a78-bd39-9dcbad3c4ff3</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#medication</sem:predicate>
      <sem:object>http://purl.bioontology.org/ontology/RXNORM/1024986</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#9a663294-b18f-4b68-847a-10984cfd9a37</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#observable-entity</sem:predicate>
      <sem:object>http://snomed.info/id/312011006</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#ca912b33-1a4e-46dc-aa0f-b9b7b9e71645</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#property</sem:predicate>
      <sem:object>http://snomed.info/id/410681005</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#b6c50038-4646-4ea2-bc8d-800b82666178</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#procedure</sem:predicate>
      <sem:object>http://snomed.info/id/386053000</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#3908591f-1d2b-4381-ae6a-a5bc815cd4f7</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#tumor-staging</sem:predicate>
      <sem:object>http://snomed.info/id/421426001</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#4ebdace9-c15a-4da4-bf60-73f3d0b119d9</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#observable-entity</sem:predicate>
      <sem:object>http://snomed.info/id/258157001</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#b45d4354-7458-47e1-a924-56c4d22e8ee4</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#medication</sem:predicate>
      <sem:object>http://purl.bioontology.org/ontology/RXNORM/1191</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#62bf69d9-7ef5-47ca-93b3-30d5b1389290</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#tumor-staging</sem:predicate>
      <sem:object>http://snomed.info/id/421426001</sem:object>
    </sem:triple>
    <sem:triple xmlns:sem="http://marklogic.com/semantics">
      <sem:subject>patient#818543da-8fa2-4f4b-b8ff-49e3d84ac65e</sem:subject>
      <sem:predicate>http://marklogic.com/demo/ontology/custom/mention#finding</sem:predicate>
      <sem:object>http://snomed.info/id/30989003</sem:object>
    </sem:triple>
  </suggested-triples>
</ont:result>
```
