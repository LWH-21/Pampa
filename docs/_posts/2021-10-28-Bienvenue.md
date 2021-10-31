---
layout: post
title:  "Lancement"
description: "Accueil sur le site"
image: /images/2021-10-18-Pampa.png
date:   2021-10-28
last_modified_at: 2021-10-31
author: LWH
locale: fr
categories: [general]
ref: welcome 
---
Pampa est un logiciel open-source de plannification de l'Aide-Ménagère aux personnes âgées. Il est en cours de développement et une première version devrait être disponible vers la fin du premier semestre 2022. Le développement a réellement commencé au troisième trimestre 2021, même j'y pense depuis juin et que je réfléchi sur sa conception, sur les outils de développement.

Par rapport aux quelques logiciels similaires existants (tous payant et très chers, ormis un seul mais qui fonctionne très mal), Pampa aura les caractéristiques suivantes :

- **Multi-SGBD**. Pampa fonctionnera avec les Systèmes de Gestion de Base de Données [SQLite](https://www.sqlite.org/index.html) (par défaut), [Mysql](https://www.mysql.com/fr/), [MariaDB](https://mariadb.org/), [PostreSQL](https://www.postgresql.org/) et [Firebird](https://firebirdsql.org/). Des tests sont en cours pour qu'il puisse s'interfacer également avec une base de données SQL Server, Oracle et même Access (mais je déconseille fortement l'usage d'Access comme base de données de Pampa).
- **Configurable**. Il est possible d'ajouter des champs dans la plupart des tables. Par exemple, si vous avez besoin d'un champ "GIR" dans la table des clients, il suffit de l'ajouter, en spécifiant qu'il s'agit d'une zone numérique pouvant prendre les valeurs 1 à 6. Ensuite, on l'ajoute à l'écran concerné et il est immédiatement utilisable. Les écrans peuvent aussi être "customisés" : on peut ajouter ou supprimer des zones de saisie, changer leur positionnement, leur taille, l'ordre de tabulation etc...
- **Multi-utilisateurs**. S'il est interfacé avec un SGBD supportant les connexions multiples (donc à peu-près tous, hormis SQLite), Pampa peut être utilisé par plusieurs personnes en même temps. Il utilise pour cela un contrôle de concurrence dit "optimiste".
- **Ergonomique**. L'interface utilisateur de Pampa est fortement inspirée de celles des navigateurs internet. C'est une interface TDI avec un historique des pages vues, une gestion des favoris etc... L'idée est que tout le monde est ajourd'hui familisarisé avec l'interface de Firefox, Google Chrome ou Internet Explorer et que chacun pourra donc s'adapter facilement à l'interface de Pampa.
- **Open Source**. Le fait que le code source soit entiérement disponible est à la fois un gage de qualité, de sécurité (pas de virus, pas de code malveillant caché) et d'avenir. Même si j'arrêtais un jour d'y travailler, un autre programmeur pourra facilement prendre le relais.
- **Gratuit**. J'ai travaillé durant l'essentiel de ma carrière pour l'action sociale et je suis assez effrayé des tarifs pratiqués par les éditeurs de logiciels. Non seulement il faut payer une licence annuelle mais en plus la moindre modification est facturée au prix fort. Et bien sûr cela se fait au détriment des bénéficiaires des associations et de leurs salariés. Pampa est destiné à être distribué gratuitement.

Bien sûr cela fait beaucoup mais les premiers résultats sont très encourageants.
