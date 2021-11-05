---
layout: post
title:  "Grille Aggir"
description: "Formulaire grille Aggir, modifiable avec calcul du GIR"
image: /images/2021-11-06-aggir.png
date:   2021-11-06
last_modified_at: 2021-11-06
author: LWH
locale: fr
categories: [social]
ref: aggir 
---


La grille AGGIR (Autonomie Gérontologique et Groupe Iso Ressources) est  utilisée pour évaluer le niveau de perte d’autonomie d’une personne :  son GIR (Groupe iso ressources).
Il s'agit d'un nombre entre 1 et 6 indiquant le degré d'autonomie de la personne évaluée.
Plus ce nombre est grand, plus une personne est autonome. On a les niveaux de dépendance suivants :

- **GIR 1**: Perte d'autonomie mentale, corporelle, locomotrice et sociale
- **GIR 2**: Fonctions mentales partiellement altérées mais capacités motrices conservées
- **GIR 3**: Autonomie mentale mais besoin d'aide pour les soins corporels
- **GIR 4**: Autonomie mentale et capacités à se déplacer au sein du domicile mais des difficultés sur certaines tâches quotidiennes
- **GIR 5**: Autonomie mentale totale et aucun problème pour ses déplacements dans son logement
- **GIR 6**: Aucun problème dans la réalisation des actes de la vie courante

La grille AGGIR est composée de 17 rubriques, appelées variables :

- **10 variables relatives à la perte d’autonomie physique et psychique**, dites **discriminantes**, car seules ces 10 variables sont utilisées pour le calcul du GIR.
- **7 autres variables**, dites **illustratives,** car elles n’entrent pas dans le calcul du GIR. Elles apportent des  informations utiles à l’élaboration du plan d’aide dans le cadre de 

Chacune de ces 17 rubriques est cotée A, B ou C :

- A correspond à des actes accomplis seul spontanément, totalement, habituellement et correctement ;
- B correspond à des actes accomplis seul qui ne sont pas  spontanément effectués, et/ou qui sont partiellement effectués et/ou qui ne sont pas habituellement effectués et/ou qui ne sont pas correctement effectués ;
- C correspond à des actes qui ne sont pas accomplis seul.

En voici l'algorithme en Python :

```python
# aggir=(COHERENCE, ORIENTATION, TOILETTE, HABILLAGE, ALIMENTATION, ELIMINATION, TRANSFERTS, DEPL. INT, DEPL EXT., COMMUNICATION )
aggir=("A","B","C","A","B","C","A","A","A","B")
rang = 0
groupe = 0
correct=True

# Test 
for i in range(8):
    if (aggir[i]!="A") and (aggir[i]!="B") and (aggir[i]!="C"):
        correct=False

if (correct):
    # Groupe A
    coefs=(2000,1200,40,40,60,100,800,200)
    for i in range(8):
        if (aggir[i]=="C"):
            groupe+=coefs[i]
    coefs=(0,0,16,16,20,16,120,32)
    for i in range(8):
        if (aggir[i]=="B"):
            groupe+=coefs[i]
    if (groupe>= 3390):
        rang=3
    if (groupe>=4140):
        rang=2
    if (groupe>=4380):
        rang=1
    # Groupe B
    if (rang==0):
        groupe=0
        coefs=(1500,1200,40,40,60,100,800,-80)
        for i in range(8):
            if (aggir[i]=="C"):
                groupe+=coefs[i]
        coefs=(320,120,16,16,0,16,120,-40)
        for i in range(8):
            if (aggir[i]=="B"):
                groupe+=coefs[i]
        if (groupe>= 2016):
            rang=4
    # Groupe C
    if (rang==0):
        groupe=0
        coefs=(0,0,40,40,60,160,1000,400)
        for i in range(8):
            if (aggir[i]=="C"):
                groupe+=coefs[i]
        coefs=(0,0,16,16,20,20,200,40)
        for i in range(8):
            if (aggir[i]=="B"):
                groupe+=coefs[i]
        if (groupe>= 1432):
            rang=6
        if (groupe>=1700):
            rang=5
    # Groupe D
    if (rang==0):
        groupe=0
        coefs=(0,0,0,0,2000,400,2000,200)
        for i in range(8):
            if (aggir[i]=="C"):
                groupe+=coefs[i]
        coefs=(0,0,0,0,0,200,200,200)
        for i in range(8):
            if (aggir[i]=="B"):
                groupe+=coefs[i]
        if (groupe>= 2400):
            rang=7
    # Groupe E
    if (rang==0):
        groupe=0
        coefs=(400,400,400,400,400,800,800,200)
        for i in range(8):
            if (aggir[i]=="C"):
                groupe+=coefs[i]
        coefs=(0,0,100,100,100,100,100,0)
        for i in range(8):
            if (aggir[i]=="B"):
                groupe+=coefs[i]
        if (groupe>= 1200):
            rang=8
    # Groupe F
    if (rang==0):
        groupe=0
        coefs=(200,200,500,500,500,500,500,200)
        for i in range(8):
            if (aggir[i]=="C"):
                groupe+=coefs[i]
        coefs=(100,100,100,100,100,100,100,0)
        for i in range(8):
            if (aggir[i]=="B"):
                groupe+=coefs[i]
        if (groupe>= 800):
            rang=9
    # Groupe G
    if (rang==0):
        groupe=0
        coefs=(150,150,300,300,500,500,400,200)
        for i in range(8):
            if (aggir[i]=="C"):
                groupe+=coefs[i]
        coefs=(0,0,200,200,200,200,200,100)
        for i in range(8):
            if (aggir[i]=="B"):
                groupe+=coefs[i]
        if (groupe>= 650):
            rang=10
     # Groupe H
    if (rang==0):
        groupe=0
        coefs=(0,0,3000,3000,3000,3000,1000,1000)
        for i in range(8):
            if (aggir[i]=="C"):
                groupe+=coefs[i]
        coefs=(
		)
        for i in range(8):
            if (aggir[i]=="B"):
                groupe+=coefs[i]
        if (groupe>= 2000):
            rang=12
        else:
            rang=13
        if (groupe>=4000):
            rang=11 
    # Girage
    if (rang==13):
        gir=6
    elif (rang==12):
        gir=5
    elif (rang==11) or (rang==10):
        gir=4
    elif (rang==9) or (rang==8):
        gir=3
    elif (rang==1):
        gir=1
    elif (rang<=7):
        gir=2
    print ("GIR: ",gir)
else:
    print("Entrée incorrecte: ",aggir)
```
