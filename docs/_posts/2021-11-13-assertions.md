---
layout: post
title:  "Assertions et programmation par contrat"
description: "Emploi des assertions en pascal et programmation par contrat"
image: /images/2021-11-13-assertions.jpg
date:   2021-11-13
last_modified_at: 2021-11-13
author: LWH
locale: fr
categories: 
  - pascal
ref: assertion 
---

Les assertions sont le moyen utilisé par le langage Pascal (du moins dans sa version Free Pascal) pour mettre en oeuvre la programmation par contrat.

Le principe en est très simple. On considère que chaque fonction, chaque procédure, chaque méthode et, en général, chaque partie du code, passe un *contrat* avec le reste du programme. 
Elle s'engage à fournir une réponse correcte si :
- Les données qu'on lui fourni en entrée respectent les règles attendues. Par exemple, pour une fonction calculant une racine carré, il est nécessaire d'avoir un nombre positif ou nul en entrée. Pour une fonction faisant la division de *a* par *b*, il est nécessaire que *b* soit différent de zéro.
- L'environnement reste conforme à ce qui est attendu. Par exemple, pour une fonction recherchant des informations dans une base de données, il faut que le programme reste connecté au SGBD.
- Si ces deux conditions sont réunies, alors, elle fournira une réponse correcte.

L'idée est donc d'*enrichir* le code en ajoutant le controle de ces données contractuelles. On aura donc :

- Des conditions initiales ou préconditions : La condition qui doit être vérifiée par le client avant le lancement d'un traitement donné. Cette condition doit garantir que l'exécution du traitement est possible sans erreur ;
- Des règles permettant d'attester que, compte-tenu des données initiales, le traitement s'est bien passe (postconditions). 
- Invariant : Il s'agit d'une condition qui est toujours vraie. Selon le type d'invariant, cette assertion caractérise l'état interne de tout le programme, ou seulement d'une partie comme pour un invariant de boucle ou un invariant d'objet.

Le langage Pascal, du moins sa version *Free Pascal* utilise les assertions pour mettre en oeuvre la programmation par contrat. Il propose pour cela une procédure *assert* définie ainsi :

```pascal
procedure Assert( Expr: Boolean,[const Msg: string]);
```

Cette procedédure teste l'expression *Expr* et, si elle est fausse, déclenche une erreur d'éxécution 227 avec le message d'erreur optionnel *Msg*. Exemple d'utilisation :

```pascal
function TDA_table.codeCalc(R : TDataSet) : shortstring;

begin
	// PreCondtions
     assert(assigned(R),'Dataset not assigned');
     assert(assigned(R.Fields.FindField('SY_CODE')),'No SY_CODE field in dataset');

     (* Some interesting code *)
	 
	 // PostCondition
	 assert((lenth(result)=7) and (result>='0000000') and (result<='ZZZZZZZ'),'Invalid code generated');
end;
```

Le comportement par défaut de l'instruction *asser* peut être modifié en affectant une procédure à la variable globale *AssertErrorProc* comme dans le code ci-dessous :

```pascal
var OldErrorProc : TAssertErrorProc;

procedure AssertionHandler( const Msg: ShortString; const Fname: ShortString; Lineno: LongInt; ErrorAddr: pointer);

begin
  if assigned(MainForm) then
  begin
    //Records in the log file of the Pampa application
    Mainform.log('Assert failed: '+msg+', Module:'+Fname+' Line n° '+inttostr(Lineno));
  end;
  // default behaviour 
  OldErrorProc(Msg,FName,LineNo,ErrorAddr);
end;

begin
  // save the default behaviour 
  OldErrorProc:=AssertErrorProc;
  // setting the new handler
  AssertErrorProc:=@AssertionHandler;  
  (* ... *)
end.
```
Il est possible d'activer ou de désactiver les assertions à la compilation. Je sais qu'il y a tout un débat sur le fait qu'il faille livrer un programme en laissant les assertions actives ou non. Pour ma part, j'estime que les assertions sont une aide à la mise au point (de même que les commentaires, les vérifications faites par le compilateur etc.) et que les utiisateurs ne devraient pas à en avoir connaissance. Mais bon.

En tous cas, il est possible de tester à l'intérieur du programme si les assertions sont actives ou non, à l'aide de la directive de compilation ```pascal {$IFOPT C+} ... {$ENDIF}```. Exemple :

```pascal
{$IFOPT C+}
//This code will only be compiled if assertions are active.
var OldErrorProc : TAssertErrorProc;

procedure AssertionHandler( const Msg: ShortString; const Fname: ShortString; Lineno: LongInt; ErrorAddr: pointer);

begin
  if assigned(MainForm) then
  begin
    //Records in the log file of the Pampa application
    Mainform.log('Assert failed: '+msg+', Module:'+Fname+' Line n° '+inttostr(Lineno));
  end;
  // default behaviour 
  OldErrorProc(Msg,FName,LineNo,ErrorAddr);
end;
{$ENDIF}

begin
{$IFOPT C+}
  // save the default behaviour 
  OldErrorProc:=AssertErrorProc;
  // setting the new handler
  AssertErrorProc:=@AssertionHandler;  
{$ENDIF}Ce
  (* ... *)
end.
```

