unit RessourcesStrings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,LMessages;


resourcestring



  rs_abandonner_modif = 'Abandonner les modifications ?';
  rs_bookmark = 'Marque-Page';
  rs_bookmarkg = 'Marque-Page commun';
  rs_confirm = 'Confirmez';
  rs_days_01 = 'Lundi';
  rs_days_02 = 'Mardi';
  rs_days_03 = 'Mercredi';
  rs_days_04 = 'Jeudi';
  rs_days_05 = 'Vendredi';
  rs_days_06 = 'Samedi';
  rs_days_07 = 'Dimanche';
  rs_loadcfg = 'Chargement des informations de configuration';
  rs_connectchoice = 'En attente des informations de connection';
  rs_connecting = 'Connection en cours...';
  rs_demande_confirmation = 'Demande de confirmation';
  rs_design = 'Modifier';
  rs_design_hint = 'Passer en mode Design';
  rs_diconnected = 'Déconnecté';
  rs_export = 'Exporter';
  rs_export_hint = 'Exporter les données';
  rs_fermeture = 'Fermeture...';
  rs_history = 'Historique' ;
  rs_idle = 'Inactif';
  rs_insert = 'Insertion';
  rs_last7days = 'Les 7 derniers jours';
  rs_month01 = 'janvier';
  rs_month02 = 'février';
  rs_month03 = 'mars';
  rs_month04 = 'avril';
  rs_month05 = 'mai';
  rs_month06 = 'juin';
  rs_month07 = 'juillet';
  rs_month08 = 'août';
  rs_month09 = 'septembre';
  rs_month10 = 'octobre';
  rs_month11 = 'novembre';
  rs_month12 = 'décembre';
  rs_monthyear = 'mmmm YYYY';
  rs_daymonth = 'DD/MM';
  rs_more6 = 'Il y a plus de 6 mois';
  rs_no='&Non';
  rs_new='Nouveau';
  rs_yes='&Oui';
  rs_period='Du %s au %s';
  rs_planning='Planning';
  rs_quit='Fermeture de Pampa';
  rs_read='Lecture';
  rs_ready='Prêt';
  rs_savechange='Enregistrer les modifications ?';
  rs_savehisto='Sauvegarde de l''historique...';
  rs_supprimer = 'Supprimer cet enregistrement ?';
  rs_today = 'Aujourd''hui';
  rs_week = 'semaine';
  rs_write = 'Ecriture';
  rs_yesterday = 'Hier';

const
  rs_month : array[1..12] of string = (rs_month01,rs_month02,rs_month03,rs_month04,rs_month05,rs_month06,rs_month07,rs_month08,rs_month09,rs_month10,rs_month11,rs_month12);

  LM_PLANNING_DEST_CHANGE = LM_USER + 1;
  LM_CAPTION_CHANGE = LM_USER + 2;
  LM_CLOSE_TAB = LM_USER + 3;

implementation



end.

