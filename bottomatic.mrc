/* 
Bottomatic 4.2
Coded By: Arruz, edited by GuybrushThreepwood
Version: 4.2
(Modified to silence notices/timers)
Change log:
4.2: Added !register function so that changing nick is not required.
4.1: Added double elim feature. Edited small coding problem in swiss. Now if a player drops out in swiss, it gives thee other player a win.
*/
;            BøttømåtiÇ™
; Current Version: [Version 1.6.6]
; Created by: Arruz
; Email suggestions: shadowgripper@gmail.com


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;; COLOR_SCHEME ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
alias -l left { return 13(13(14~13~14    }
alias -l right { return 13   14~13~13)13) }

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;; THE_BOTTOMATIC_CODE ;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Alias F1 bottomatic
alias bottomatic { /dialog -md bottomatic bottomatic }
alias open { bottomatic }
On *:START: {
  If (%Tournament.isOn == Off) {
    Set %BigButton.state 1
  }
  Echo -a $left 14[Bottomatic] Type 13/bottomatic to the open the Bottomatic commands window. $right
  If (!%BottomaticUser) {
    createVariables
  }
}

;;;;;;;;;; INIT ;;;;;;;;;;
on *:DIALOG:bottomatic:init:0: {
  /did -ra bottomatic 11 %Tournament.isOn
  /did -ra bottomatic 12 %Registration.isOn
  /did -ra bottomatic 13 %Swiss.isOn

  Set %H 0
  Set %F 0
  Set %C 0
  Var %Count = 1
  While ($Read(listing.txt, %Count) != $Null) {
    If ($Left($Read(listing.txt, %Count), 3) == |F|) { Inc %F }
    Elseif ($Left($Read(listing.txt, %Count), 3) == |H|) { Inc %H }
    Else { Inc %C }
    /did -a bottomatic 3 $gettok($Read(listing.txt, %Count),1,32)
    Inc %Count
  }
  Set %Count 1
  While ($Read(ListingWas.txt, %Count) != $Null) {
    /did -a bottomatic 23 $gettok($Read(ListingWas.txt, %Count),1,32)
    Inc %Count
  }
  /did -ra bottomatic 27 -- $getRating --
  /did -ra bottomatic 14 %H
  /did -ra bottomatic 15 %F
  /did -ra bottomatic 16 %C
  /did -ra bottomatic 19 $calc(%H + %F + %C)

  updateBigButton
  showDialogBrackets 1
  .TimerUpdateIt 0 1 updateBigButton
}
on *:DIALOG:bottomatic:close:0: { .TimerUpdateIt off }

;;;;;;;;;; BIG_BUTTON ;;;;;;;;;;
on *:DIALOG:bottomatic:sclick:20: {
  If (%BigButton.state == 1) {
    Set %Tournament.isOn On
    /did -ra bottomatic 11 %Tournament.isOn
    Msg %Tournament.Channel $left The tournament is now: $iif(%Tournament.isOn == On,13ON,7OFF) $right
    /dialog -mvd rules_notepad rules_notepad
    /dialog -e bottomatic
    Set %BigButton.state 2
    updateBigButton
    SockOpen checkupdate arruz.bravehost.com 80
  }

  Elseif (%BigButton.state == 2) {
    Set %Registration.isOn On
    /did -ra bottomatic 12 %Registration.isOn
    Msg %Tournament.Channel $left Registration is now: $iif(%Registration.isOn == On,13ON,7OFF) $right
    Mode %Tournament.Channel -i
    Set %BigButton.state 3
    updateBigButton
  }

  Elseif (%BigButton.state == 3) {
    Mode %Tournament.Channel +mi
    Set %Registration.isOn Off
    /did -ra bottomatic 12 %Registration.isOn
    Msg %Tournament.Channel $left Registration is now: $iif(%Registration.isOn == On,13ON,7OFF) $right
    bottomatic_mass_devoice
    Set %BigButton.state 4
    updateBigButton
  }

  Elseif (%BigButton.state == 4) {
    Msg %Tournament.Channel $left Rules: %Rules Bans: %BannedCards Match Type: %MatchType Time Limit: %TimeLimit minutes. $right
    Msg %Tournament.Channel $left Both winners and losers please report match results. --- Winners type !Win and Losers type !Loss --- If you opponent disconnects or is not here, then please wait 5 minutes. $right 
    If (%Swiss.isOn == On) {
      Msg %Tournament.Channel $left This tournament is Swiss Style. You are not eliminated when you lose. You stay and play through a set number of rounds. The highest ranking people will advance to the finals. $right 
    }
    Else If (%Swiss.isOn == Dbl) {
      Msg %Tournament.Channel $left This tournament is Double Elimination. You are not eliminated the first time that you lose. You stay and duel until you lose 2 matches. $right 
    }
    Set %BigButton.state 5
    updateBigButton
  }

  Elseif (%BigButton.state == 5) {
    createBrackets
    showDialogBrackets 1
    .Timer 1 10 Mode %Tournament.Channel -m
    Set %BigButton.state 6
    updateBigButton
  }

  Elseif (%BigButton.state == 6) {
    Msg %Tournament.Channel $left Time before the next round: $getTimeLeft $+ . $right
  }

  Elseif (%BigButton.state == 7) {
    Inc %Current.Round
    /did -ra bottomatic 26 %Current.Round
    Mode %Tournament.Channel +m
    bottomatic_mass_devoice
    Set %BigButton.state 4
    updateBigButton
  }

  Elseif (%BigButton.state == 8) {
    Write -c brackets.txt
    .TimerBracket off
    .TimerTourneyEnd off
    showDialogBrackets 1
    bottomatic_mass_remove
    Set %Current.Round 1
    /did -ra bottomatic 26 %Current.Round
    Set %Tournament.isOn Off
    /did -ra bottomatic 11 %Tournament.isOn
    Msg %Tournament.Channel $left The tournament is now: $iif(%Tournament.isOn == On,13ON,7OFF) $right
    Set %BigButton.state 1
    updateBigButton
  }
}

;;;;;;;;;; RESET_SCRIPT ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:42: {
  If ($input(Are you sure you want to reset the tournament?,yv) == $yes) {
    Write -c brackets.txt
    .TimerBracket off
    .TimerTourneyEnd off
    showDialogBrackets 1
    bottomatic_mass_remove
    Set %Current.Round 1
    /did -ra bottomatic 26 %Current.Round
    Set %Tournament.isOn Off
    /did -ra bottomatic 11 %Tournament.isOn
    Set %Registration.isOn Off
    /did -ra bottomatic 12 %Registration.isOn
    Set %Swiss.isOn Off
    /did -ra bottomatic 13 %Swiss.isOn
    Msg %Tournament.Channel $left The tournament has been reset. $right
    Set %BigButton.state 1
    updateBigButton
  }
}

;;;;;;;;;; SWISS_DISPLAY_TOP_# ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:70: {
  If (%Tournament.isOn != On) || (%Swiss.isOn != On) { Halt }
  Var %MaxPeople = $$?="Display the top how many people? (Enter a number only)"
  sortRankings
  If (%MaxPeople) {
    Var %Count = 1
    Msg %Tournament.Channel $left 10Top %MaxPeople Rankings $right
    While (%Count < $calc(%MaxPeople + 1)) && ($Read(listing.txt, %Count) != $Null) {
      Msg %Tournament.Channel $left $+(10, %Count, .)  $gettok($Read(listing.txt, %Count),1,32) 10 $+ $gettok($Read(listing.txt, %Count),2,32) $+ - $+ $gettok($Read(listing.txt, %Count),3,32) with10 $gettok($Read(listing.txt, %Count),4,32)  extra points. $right
      Inc %Count
    }
  }
}

;;;;;;;;;; SWISS_VOICE_TOP_# ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:71: {
  If (%Tournament.isOn != On) || (%Swiss.isOn != On) { Halt }
  Var %MaxPeople = $$?="Voice the top how many people? (Enter a number only)"
  sortRankings
  If (%MaxPeople) {
    Var %Count = 1
    While (%Count < $calc(%MaxPeople + 1)) && ($Read(listing.txt, %Count) != $Null) {
      Mode %Tournament.Channel +v $gettok($Read(listing.txt, %Count),1,32)
      Inc %Count
    }
  }
}

;;;;;;;;;; MASS_DEVOICE ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:57: {
  If (%Tournament.isOn != On) { Halt }
  bottomatic_mass_devoice
}

;;;;;;;;;; MASS_ADD_EVERYONE ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:58: {
  If (%Tournament.isOn != On) { Halt }
  bottomatic_mass_add
}

;;;;;;;;;; MASS_REMOVE_EVERYONE ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:59: {
  If (%Tournament.isOn != On) { Halt }
  bottomatic_mass_remove
}

;;;;;;;;;; MASS_KICK_NON-VOICES ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:60: {
  If (%Tournament.isOn != On)  { Halt }
  Var %Count = 1
  Var %Person = Unknown
  Var %PersonStatus = X
  Set %Person $Nick(%Tournament.Channel,%Count)
  While (%Person) {
    Set %PersonStatus $Left($Nick(%Tournament.Channel,%Count).pnick,1)
    If (%PersonStatus != ~) && (%PersonStatus != &) && (%PersonStatus != @) && (%PersonStatus != %) && (%PersonStatus != +) {
      removeFromListing %Person
      Kick %Tournament.Channel %Person Thanks for showing up! Goodbye. BøttømåtiÇ™
    }
    Inc %Count
    Set %Person $Nick(%Tournament.Channel,%Count)
  }
}

;;;;;;;;;; MASS_KICK_NON-PARTICIPANTS ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:61: {
  If (%Tournament.isOn != On) { Halt }
  Var %Count = 1
  Var %Person = Unknown
  Var %PersonStatus = X
  Set %Person $Nick(%Tournament.Channel,%Count)
  While (%Person) {
    Set %PersonStatus $Left($Nick(%Tournament.Channel,%Count).pnick,1)
    If ($findNick(%Person, listing.txt) == 0) && ($Left(%Person, 3) != |W|) && (%PersonStatus != ~) && (%PersonStatus != &) && (%PersonStatus != @) && (%PersonStatus != %) {
      Kick %Tournament.Channel %Person You did not register in time. BøttømåtiÇ™
    }
    Inc %Count
    Set %Person $Nick(%Tournament.Channel,%Count)
  }
}

;;;;;;;;;; MASS_KICK_LOSERS ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:62: {
  If (%Tournament.isOn != On) { Halt }
  Var %Count = 1
  While ($Read(losers.txt, %Count) != $Null) {
    If ($Read(losers.txt, %Count) ison %Tournament.Channel) {
      Kick %Tournament.Channel $Read(losers.txt, %Count) Lost and did not change nick. BøttømåtiÇ™
    }
    Inc %Count
  }
}

;;;;;;;;;; CLICK_PARTICIPANT_ON_LISTINGS ;;;;;;;;;;
on *:DIALOG:bottomatic:sclick:3,23: {
  updatePersonStatus $did($did).seltext
}

;;;;;;;;;; INDIVIDUAL_STATUS_NAME ;;;;;;;;;;
on *:DIALOG:bottomatic:edit:51: { 
  If ($did(51)) && ($did(51) != $char(32)) {
    Var %PersonData = $deltok($Read(listing.txt, $findNick($did(51), listing.txt)),1,32)
    If (%PersonData) {
      /did -ra bottomatic 36 $gettok(%PersonData,1,32)
      /did -ra bottomatic 37 $gettok(%PersonData,2,32)
      /did -ra bottomatic 38 $gettok(%PersonData,3,32)
    }
    Else {
      /did -ra bottomatic 36 -
      /did -ra bottomatic 37 -
      /did -ra bottomatic 38 -
    }
  }
}

;;;;;;;;;; INDIVIDUAL_STATUS_ADD ;;;;;;;;;;
on *:DIALOG:bottomatic:sclick:31: { 
  If (%Tournament.isOn != On) || (!$did(51)) { Halt }
  Var %PersonData 
  If (!$didwm(bottomatic,3,$did(51))) && (!$didwm(bottomatic,23,$did(51))) {
    addToListing $did(51) 0 0 10
    /did -ra bottomatic 36 0
    /did -ra bottomatic 37 0
    /did -ra bottomatic 38 10
  }
  Elseif ($didwm(bottomatic,23,$did(51))) {
    Set %PersonData $deltok($Read(ListingWas.txt, $findNick($did(51), ListingWas.txt)),1,32)
    removeFromListingWas $did(51)
    addToListing $did(51) %PersonData
    If (%PersonData) {
      /did -ra bottomatic 36 $gettok(%PersonData,1,32)
      /did -ra bottomatic 37 $gettok(%PersonData,2,32)
      /did -ra bottomatic 38 $gettok(%PersonData,3,32)
    }
  }
  If (%Registration.isOn == On) { 
  Mode %Tournament.Channel +v $did(51) }
}

;;;;;;;;;; INDIVIDUAL_STATUS_REMOVE ;;;;;;;;;;
on *:DIALOG:bottomatic:sclick:32: { 
  If (%Tournament.isOn != On) || (!$did(51)) { Halt }
  Var %PersonData 
  If ($didwm(bottomatic,23,$did(51))) {
    removeFromListingWas $did(51)
  }
  Elseif ($didwm(bottomatic,3,$did(51))) {
    removeFromListing $did(51)
  }
  /did -ra bottomatic 36 -
  /did -ra bottomatic 37 -
  /did -ra bottomatic 38 -
  /did -r bottomatic 51
  Mode %Tournament.Channel -v $did(51)
}

;;;;;;;;;; INDIVIDUAL_STATUS_!WIN ;;;;;;;;;;
on *:DIALOG:bottomatic:sclick:29: { 
  If (%Tournament.isOn != On) || (!$did(51)) { Halt }
  Var %PersonData
  If ($didwm(bottomatic,23,$did(51))) {
    Set %PersonData $deltok($Read(ListingWas.txt, $findNick($did(51), ListingWas.txt)),1,32)
  }
  Elseif ($didwm(bottomatic,3,$did(51))) {
    Set %PersonData $deltok($Read(listing.txt, $findNick($did(51), listing.txt)),1,32)
  }
  If (%PersonData) && (%Swiss.isOn == On) && ($calc($gettok(%PersonData,1,32) + $gettok(%PersonData,2,32)) >= %Current.Round) {
    Echo $active $left $did(51) has already been given a win/loss for this round. $right
  }
  Else {
    declare_winner $did(51)
  }

  If (%PersonData) {
    /did -ra bottomatic 36 $gettok(%PersonData,1,32)
    /did -ra bottomatic 37 $gettok(%PersonData,2,32)
    /did -ra bottomatic 38 $gettok(%PersonData,3,32)
  }
}

;;;;;;;;;; INDIVIDUAL_STATUS_!LOSE ;;;;;;;;;;
on *:DIALOG:bottomatic:sclick:30: { 
  If (%Tournament.isOn != On) || (!$did(51)) { Halt }
  Var %PersonData
  If ($didwm(bottomatic,23,$did(51))) {
    Set %PersonData $deltok($Read(ListingWas.txt, $findNick($did(51), ListingWas.txt)),1,32)
  }
  Elseif ($didwm(bottomatic,3,$did(51))) {
    Set %PersonData $deltok($Read(listing.txt, $findNick($did(51), listing.txt)),1,32)
  }
  If (%PersonData) && (%Swiss.isOn == On) && ($calc($gettok(%PersonData,1,32) + $gettok(%PersonData,2,32)) >= %Current.Round) {
    Echo $active $left $did(51) has already been given a win/loss for this round. $right
  }
  Else {
    declare_loser $did(51)
  }

  If (%PersonData) {
    /did -ra bottomatic 36 $gettok(%PersonData,1,32)
    /did -ra bottomatic 37 $gettok(%PersonData,2,32)
    /did -ra bottomatic 38 $gettok(%PersonData,3,32)
  }
}

;;;;;;;;;; INDIVIDUAL_STATUS_EDIT ;;;;;;;;;;
on *:DIALOG:bottomatic:sclick:72: { 
  If (%Tournament.isOn != On) || (!$did(51)) { Halt }
  Var %PersonData
  If ($didwm(bottomatic,23,$did(51))) {
    Set %PersonData $deltok($Read(ListingWas.txt, $findNick($did(51), ListingWas.txt)),1,32)
  }
  Elseif ($didwm(bottomatic,3,$did(51))) {
    Set %PersonData $deltok($Read(listing.txt, $findNick($did(51), listing.txt)),1,32)
  }
  If (%PersonData) {
    Var %B.Wins = $$?="How many wins should $did(51) have? Current amount: $gettok(%PersonData,1,32) "
    Var %B.Losses = $$?="How many losses should $did(51) have? Current amount: $gettok(%PersonData,2,32) "
    Var %B.Score = $$?="How many tie breaker points should $did(51) have? Current amount: $gettok(%PersonData,3,32) "
    /did -ra bottomatic 36 %B.Wins
    /did -ra bottomatic 37 %B.Losses
    /did -ra bottomatic 38 %B.Score
    If ($didwm(bottomatic,23,$did(51))) {
      Write -l $+ $findNick($did(51), ListingWas.txt) ListingWas.txt $did(51) $iif(%B.Wins,%B.Wins,0) $iif(%B.Losses,%B.Losses,0) $iif(%B.Score,%B.Score,0)
    }
    Elseif ($didwm(bottomatic,3,$did(51))) {
      Write -l $+ $findNick($did(51), listing.txt) listing.txt $did(51) $iif(%B.Wins,%B.Wins,0) $iif(%B.Losses,%B.Losses,0) $iif(%B.Score,%B.Score,0)
    }
  }
}
;;;;;;;;;; INDIVIDUAL_STATUS_KICK ;;;;;;;;;;
on *:DIALOG:bottomatic:sclick:73: { 
  If (%Tournament.isOn != On) || (!$did(51)) { Halt }
  If ($didwm(bottomatic,23,$did(51))) {
    removeFromListingWas $did(51)
  }
  Elseif ($didwm(bottomatic,3,$did(51))) {
    removeFromListing $did(51)
  }
  Kick %Tournament.Channel $did(51) Goodbye.
  /did -ra bottomatic 36 -
  /did -ra bottomatic 37 -
  /did -ra bottomatic 38 -
  /did -r bottomatic 51
}

;;;;;;;;;; TOURNAMENT_ON_OFF ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:40: {
  Set %Tournament.isOn $iif(%Tournament.isOn == On,Off,On)
  /did -ra bottomatic 11 %Tournament.isOn
  SockOpen checkupdate arruz.bravehost.com 80
  If (Off isin %Tournament.isOn) { 
    .TimerBracket off 
  }
  Msg %Tournament.Channel $left The tournament is now turned: $iif(%13To14urnament.13i14sOn == On,13ON,7OFF) $right
}
;;;;;;;;;; REGISTRATION_ON_OFF ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:41: {
  Set %Registration.isOn $iif(%Registration.isOn == On,Off,On)
  /did -ra bottomatic 12 %Registration.isOn
  If (On isin %Tournament.isOn) { 
    Msg %Tournament.Channel $left Registration is now turned: $iif(%Registration.isOn == On,13ON,7OFF) $right
  }
}
;;;;;;;;;; SWISS_ON_OFF ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:69: {
  Set %Swiss.isOn $iif(%Swiss.isOn == On,Off,On)
  /did -ra bottomatic 13 %Swiss.isOn
  If (On isin %Tournament.isOn) { 
    Msg %Tournament.Channel $left Swiss Style is now turned: $iif(%Swiss.isOn == On,3ON,4OFF) $right
  }
}
on *:DIALOG:bottomatic:menu:200: {
  Set %Swiss.isOn $iif(%Swiss.isOn == Dbl,Off,Dbl)
  /did -ra bottomatic 13 %Swiss.isOn
  If (On isin %Tournament.isOn) { 
    Msg %Tournament.Channel $left Double Elimination is now turned: $iif(%Swiss.isOn == Dbl,3ON,4OFF) $right
  }
}

;;;;;;;;;; SET_TOURNEY_CHANNEL ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:46: { 
  Set %Tournament.Channel $$?="Enter the channel for the tournament. (ie: #arruz)"
  /did -ra bottomatic 17 %Tournament.Channel
}

;;;;;;;;;; CHANGE_BIG_BUTTON_STATE ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:109: {
  /dialog -mvd bigbutton_state bigbutton_state
  /dialog -e bottomatic
  /did -c bigbutton_state $calc(%BigButton.state + 1)
}

;;;;;;;;;; VIEW/EDIT_RULES ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:43: {
  /dialog -mvd rules_notepad rules_notepad
  /dialog -e bottomatic
}

;;;;;;;;;; DISPLAY_RULES ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:44: {
  If (%Tournament.isOn != On) { Halt }
  Msg %Tournament.Channel $left Rules: %Rules Bans: %BannedCards Match Type: %MatchType Time Limit: %TimeLimit minutes. $right
}

;;;;;;;;;; DISPLAY_HOW_TO_REGISTER ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:55: {
  If (%Tournament.isOn != On) { Halt }
  Msg %Tournament.Channel $left Register Instructions: %Instructions $right
}

;;;;;;;;;; ADVERTISE_TOURNEY ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:54: {
  If (%Tournament.isOn != On) { Halt }
  Var %AdvertiseWhere = $$?="Advertise to what channel? (Include the '#' as in #moo)"
  If (%AdvertiseWhere) {
    Set %ChannelAdvertiseOK $addtok(%ChannelAdvertiseOK,%AdvertiseWhere,32)
    If ($me ison %AdvertiseWhere) {
      hadd -m advwhere %AdvertiseWhere %AdvertiseWhere
      Msg %AdvertiseWhere $left I have been sent to advertise a tournament. If this is ok, have a half-op or higher status person type: Yes Advertise or type No Advertise $right
    }
    Else {
      if (%AdvertiseWhere == #yvd || %AdvertiseWhere == #rulings || %AdvertiseWhere == #helpdesk || %AdvertiseWhere == #xct) { advertisecheck | halt }
      Join %AdvertiseWhere 
      .Timer 1 1 Msg %AdvertiseWhere $left I have been sent to advertise a tournament. If this is ok, have a half-op or higher status person type: Yes Advertise or type No Advertise to send me away. $right
    }
    .Timerad $+ %AdvertiseWhere  1 300 advertisecheck %AdvertiseWhere 
  }
}
On *:TEXT:*Advertise*:#: {
  If ($istok(%ChannelAdvertiseOK,$chan,32)) {
    If ($chr(37) isin $Nick($chan,$Nick).pnick) || ($chr(64) isin $Nick($chan,$Nick).pnick) || ($chr(38) isin $Nick($chan,$Nick).pnick) || ($chr(126) isin $Nick($chan,$Nick).pnick) {
      If (Yes Advertise isin $strip($1-$2)) {
        If (On isin %Tournament.isOn) { Msg $chan $left Tournament in %Tournament.Channel $right }
        If ($hget(advwhere,$chan)) { hdel advwhere $chan }
        Else { Part $chan Goodbye }
        Echo %Tournament.Channel $left [BøttømåtiÇ™] Advertised successfully in $chan $right
        Set %ChannelAdvertiseOK $remtok(%ChannelAdvertiseOK,$chan,32)
        .Timerad $+ $chan Off
      }
      Elseif (No Advertise isin $strip($1-$2)) {
        If ($hget(advwhere,$chan)) { hdel advwhere $chan }
        Else { Part $chan Goodbye }
        Echo %Tournament.Channel $left [BøttømåtiÇ™] You were rejected from advertising in $chan by $Nick $right
        Set %ChannelAdvertiseOK $remtok(%ChannelAdvertiseOK,$chan,32)
        .Timerad $+ $chan Off
      }
    }
  }
}
alias advertisecheck {
  Echo %Tournament.Channel $left [BøttømåtiÇ™] Advertisement failed: there was no response in $1 $+ , or you attempted to advertise $+
  in a blocked channel. $right 
  Set %ChannelAdvertiseOK $remtok(%ChannelAdvertiseOK,$1,32)
  If ($hget(advwhere,$1)) { hdel advwhere $1 }
  Else { Part $1 Goodbye }
}

;;;;;;;;;; INVITE_A_PERSON ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:53: {
  /invite $$?="Invite who to join?" %Tournament.Channel
}

;;;;;;;;;; DISPLAY_BRACKETS ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:65: {
  If (%Tournament.isOn != On) { Halt }
  Msg %Tournament.Channel $left 10Remaining Matches $right
  If ($Read(brackets.txt) == $Null) { 
    Msg %Tournament.Channel $left There are no more remaining matches. $right
  }
  Else { 
    Var %Count = 1
    While ($Read(brackets.txt, %Count)) {
      Msg %Tournament.Channel $left $+(10, %Count, .)  $Read(brackets.txt, %Count) $right
      Inc %Count
    }
  }
  .TimerRemainingCommand 1 60 .TimerRemainingCommand off
}

;;;;;;;;;; DISPLAY_BRACKET_.Timer ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:66: {
  If (%Tournament.isOn != On) { Halt }
  If ($Timer(Bracket).secs > 0) {
    Msg %Tournament.Channel $left Time before the next round: $getTimeLeft $+ . $right
  }
  Else {
    Msg %Tournament.Channel $left There is no bracket Timer active. $right
  }
}

;;;;;;;;;; EDIT_BRACKET_.Timer ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:67: {
  If (%Tournament.isOn != On) { Halt }
  Var %TimeChange = $gettok($$?="What is the new time (in minutes) for the bracket Timer? (Enter a number only, enter '0' to stop the .Timer)",1,32)
  If (%TimeChange == 0) { 
    .TimerBracket Off 
    Msg %Tournament.Channel $left The bracket Timer has been turned off. $right
  }
  ElseIf (%TimeChange) {
    .TimerBracket Off
    .TimerBracket 1 $calc(%TimeChange * 60) bracket.TimerEnded
    Msg %Tournament.Channel $left The bracket Timer has been reset to %TimeChange minute $+ $iif(%TimeChange != 1,s) $+ . $right
  }
}

;;;;;;;;;; MUTE ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:48: {
  If (%Tournament.isOn != On) { Halt }
  Mode %Tournament.Channel +m
}
;;;;;;;;;; UN-MUTE ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:49: {
  If (%Tournament.isOn != On) { Halt }
  Mode %Tournament.Channel -m
}
;;;;;;;;;; LOCK ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:28: {
  If (%Tournament.isOn != On) { Halt }
  Mode %Tournament.Channel +i
}
;;;;;;;;;; UN-LOCK ;;;;;;;;;;
on *:DIALOG:bottomatic:menu:52: {
  If (%Tournament.isOn != On) { Halt }
  Mode %Tournament.Channel -i
}

;;;;;;;;;; EDIT_BRACKET_LINE ;;;;;;;;;;
on *:DIALOG:bottomatic:sclick:101,102,103,104,105,106: {
  Var %Count = $calc($did - 101)
  If ($did($calc(101 + %Count)) == Edit) {
    /did -n bottomatic $calc(89 + %Count)
    /did -n bottomatic $calc(95 + %Count)
    /did -ra bottomatic $calc(101 + %Count) Save
  }
  Else {
    If ($did($calc(89 + %Count))) {
      Write -l $+ $left($did($calc(77 + %Count)), -1) brackets.txt $gettok($did($calc(89 + %Count)),1,32) vs. $gettok($did($calc(95 + %Count)),1,32) 
      Var %Line = $Read(brackets.txt, $left($did($calc(77 + %Count)), -1))
      /did -mra bottomatic $calc(89 + %Count) $gettok(%Line,1,32)
      /did -mra bottomatic $calc(95 + %Count) $iif($gettok(%Line,3,32) == a, BYE, $gettok(%Line,3,32))
    }
    Else {
      Write -dl $+ $left($did($calc(77 + %Count)), -1) brackets.txt
      showDialogBrackets $left($did(77), -1)
    }

    /did -ra bottomatic $calc(101 + %Count) Edit
    If ($Read(brackets.txt) == $Null) && ($getTimeLeft > 0) {
      /beep
      .TimerBracket off
      Echo $active $left Notice: All matches have finished in10 %Tournament.Channel before the time limit ended. $right
    }
  }
}

;;;;;;;;;; PRESS_^_BUTTON ;;;;;;;;;;
on *:DIALOG:bottomatic:sclick:110,111,112,113,114,115,116,117,118,119,120,121: {
  updatePersonStatus $did($calc($did - 21))
}

;;;;;;;;;; PREVIOUS_BRACKET_GROUP ;;;;;;;;;;
on *:DIALOG:bottomatic:sclick:107: {
  Var %TopMatch = $left($did(77), -1)
  If (%TopMatch != 1) {
    Dec %TopMatch 6
    If (%Topmatch < 1) { 
      Set %TopMatch 1
    }
    showDialogBrackets %TopMatch
  }
}

;;;;;;;;;; NEXT_BRACKET_GROUP ;;;;;;;;;;
on *:DIALOG:bottomatic:sclick:108: {
  Var %TopMatch = $left($did(82), -1)
  If ($Read(brackets.txt, %TopMatch)) {
    Inc %TopMatch
    showDialogBrackets %TopMatch
  }
}

;;;;;;;;;; RULES_CLICK_APPLY ;;;;;;;;;;
on *:DIALOG:rules_notepad:sclick:14: {
  If ($did(8)) { Set %Instructions $did(8) }
  If ($did(9)) { Set %Rules $did(9) }
  If ($did(10)) { Set %BannedCards $did(10) }
  If ($did(11)) { Set %Prize $did(11) }
  If ($did(12)) { Set %MatchType $did(12) }
  If ($did(13)) { Set %TimeLimit $gettok($did(13),1,32) }
  /dialog -x rules_notepad rules_notepad
}
;;;;;;;;;; RULES_CLICK_CANCEL ;;;;;;;;;;
on *:DIALOG:rules_notepad:sclick:15: { 
  /dialog -x rules_notepad rules_notepad 
}
;;;;;;;;;; RULES_CLICK_LOAD_FILE ;;;;;;;;;;
on *:DIALOG:rules_notepad:sclick:16: {
  Var %RulesFile = $sfile($mircdir,Please select a rulings file to LOAD:)
  If (%RulesFile) {
    /did -ra rules_notepad 8 $Read(%RulesFile,1)
    /did -ra rules_notepad 9 $Read(%RulesFile,2)
    /did -ra rules_notepad 10 $Read(%RulesFile,3)
    /did -ra rules_notepad 11 $Read(%RulesFile,4)
    /did -ra rules_notepad 12 $Read(%RulesFile,5)
    /did -ra rules_notepad 13 $Read(%RulesFile,6)
  }
}
;;;;;;;;;; RULES_CLICK_SAVE_TO_FILE ;;;;;;;;;;
on *:DIALOG:rules_notepad:sclick:17: {
  Var %RulesFile = $sfile($mircdir,Please select a place and name to SAVE:,Save)
  If (%RulesFile) {
    Write -c %RulesFile
    Write %RulesFile $iif($did(8),$did(8),-)
    Write %RulesFile $iif($did(9),$did(9),-)
    Write %RulesFile $iif($did(10),$did(10),-)
    Write %RulesFile $iif($did(11),$did(11),-)
    Write %RulesFile $iif($did(12),$did(12),-)
    Write %RulesFile $iif($did(13),$gettok($did(13),1,32),-)
  }
}

;;;;;;;;;; BIGBUTTON_CLICK_APPLY ;;;;;;;;;;
on *:DIALOG:bigbutton_state:sclick:10: {
  If ($did(2).state) { Set %BigButton.state 1 | updateBigButton }
  If ($did(3).state) { Set %BigButton.state 2 | updateBigButton }
  If ($did(4).state) { Set %BigButton.state 3 | updateBigButton }
  If ($did(5).state) { Set %BigButton.state 4 | updateBigButton }
  If ($did(6).state) { Set %BigButton.state 5 | updateBigButton }
  If ($did(7).state) { 
    If (!$Timer(Bracket)) { .TimerBracket 1 $calc($gettok($$?="Enter the time (in minutes only) for the bracket Timer:",1,32)*60) bracket.TimerEnded }
    Set %BigButton.state 6 
    updateBigButton 
  }
  If ($did(8).state) { Set %BigButton.state 7 | updateBigButton }
  If ($did(9).state) { Set %BigButton.state 8 | updateBigButton }
  /dialog -x bigbutton_state bigbutton_state
}
;;;;;;;;;; CLICK_CANCEL ;;;;;;;;;;
on *:DIALOG:bigbutton_state:sclick:11: {
  /dialog -x bigbutton_state bigbutton_state
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; CHANNEL_EVENTS ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
On *:JOIN:%Tournament.Channel {
  If (%Tournament.isOn == On) {
    If ($findNick($Nick, ListingWas.txt)) && (!$findNick($Nick, losers.txt)) {
      addToListing $Nick $deltok($Read(ListingWas.txt, $findNick($Nick, ListingWas.txt)),1,32) 
      removeFromListingWas $Nick
      .notice $Nick $left You have been added back into the tournament listings. $right
      If (!$Read(brackets.txt,w,$+(*,$Nick,*))) || (%Registration.isOn == On) { Mode %Tournament.Channel +v $Nick }
    }
    ElseIf (On isin %Registration.isOn) {
      If ($Left($Nick,3) == |H|) || ($Left($Nick,3) == |F|) || ($Left($Nick,3) == |C|) {
        addToListing $Nick 0 0 10
        Mode %Tournament.Channel +v $Nick
      }
    }
  }
}

On *:NICK {
  If (%Tournament.isOn == On) && ($NewNick ison %Tournament.Channel) {
    If ($Left($NewNick,3) == |H|) || ($Left($NewNick,3) == |F|) || ($Left($NewNick,3) == |C|) {
      If ($findNick($NewNick, ListingWas.txt)) && (!$findNick($NewNick, losers.txt)) {
        addToListing $NewNick $deltok($Read(ListingWas.txt, $findNick($NewNick, ListingWas.txt)),1,32) 
        removeFromListingWas $NewNick
        .notice $NewNick $left You have been added back into the tournament listings. $right
        If (!$Read(brackets.txt,w,$+(*,$Nick,*))) || (%Registration.isOn == On) { Mode %Tournament.Channel +v $Nick }
      }
      Else {
        If ($findNick($Nick, listing.txt)) {
          Var %PersonData = $deltok($Read(listing.txt, $findNick($Nick, listing.txt)),1,32)
          removeFromListing $Nick
          .Timer 1 1 addToListing $NewNick %PersonData

          Var %Count = 1
          while ($Read(brackets.txt, %Count)) {
            If ($gettok($Read(brackets.txt, %Count),1,32) == $Nick) { 
              Write -l $+ $Readn brackets.txt $NewNick vs. $gettok($Read(brackets.txt, %Count),3,32)
              If ($dialog(bottomatic)) { showDialogBrackets $left($did(bottomatic,77), -1) }
              /break
            }
            ElseIf ($gettok($Read(brackets.txt, %Count),3,32) == $Nick) { 
              Write -l $+ $Readn brackets.txt $gettok($Read(brackets.txt, %Count),1,32) vs. $NewNick 
              If ($dialog(bottomatic)) { showDialogBrackets $left($did(bottomatic,77), -1) }
              /break
            }
            Inc %Count
          }
          .notice $NewNick $left Your nick for the tournament has been updated. $right
        }
        ElseIf (On isin %Registration.isOn) {
          addToListing $NewNick 0 0 10
          Mode %Tournament.Channel +v $NewNick
        }
      }
    }

    ElseIf ($findNick($Nick, listing.txt)) {
      Var %PersonData = $deltok($Read(listing.txt, $findNick($Nick, listing.txt)),1,32)
      removeFromListing $Nick
      addToListingWas $Nick %PersonData
      Mode %Tournament.Channel -v $NewNick
      .notice $NewNick $left Your name has been removed from the tournament listing. If you want back in, please change your nick back to your original nick: $Nick $right
    }
  }
}

On *:PART:%Tournament.Channel: {
  If (%Tournament.isOn != On) { Halt }
  If ($Left($Nick,3) == |W|) {
    Mode %Tournament.Channel +I $Nick
    .TimerI $+ $Nick 1 300 Mode %Tournament.Channel -I $Nick
  }
  ElseIf ($findNick($Nick, listing.txt)) {
    Var %PersonData = $deltok($Read(listing.txt, $findNick($Nick, listing.txt)),1,32)
    removeFromListing $Nick
    If (!$findNick($Nick, losers.txt)) {
      addToListingWas $Nick %PersonData
      Mode %Tournament.Channel +I $Nick
      .TimerI $+ $Nick 1 300 removeFromListingWas $Nick
    }
  }
}
On *:KICK:%Tournament.Channel: {
  If (%Tournament.isOn != On) { Halt }
  removeFromListing $Nick
}
On *:QUIT: {
  If (%Tournament.isOn != On) { Halt }
  If ($Left($Nick,3) == |W|) {
    ;; Mode %Tournament.Channel +I $Nick
    ;; .TimerI $+ $Nick 1 300 Mode %Tournament.Channel -I $Nick
    ;; Removed because QUIT is global and not restricted to Tournament Channel only
  }
  ElseIf ($findNick($Nick, listing.txt)) {
    Var %PersonData = $deltok($Read(listing.txt, $findNick($Nick, listing.txt)),1,32)
    removeFromListing $Nick
    If (!$findNick($Nick, losers.txt)) {
      addToListingWas $Nick %PersonData
      Mode %Tournament.Channel +I $Nick
      .TimerI $+ $Nick 1 300 removeFromListingWas $Nick
    }
  }
}

On *:TEXT:*:%Tournament.Channel: {
  If (%Tournament.isOn != On) { Halt }
  If ($1 == !Credits) || ($1 == .Credits) {
    If (!$Timer(CreditsCommand).secs) {
      Msg %Tournament.Channel $left Credits to Arruz for creating BøttømåtiÇ™ 4.0. BøttømåtiÇ™ 4.1 updated and maintained by GuybrushThreepwood. $right
      .TimerCreditsCommand 1 30 .TimerCreditsCommand off
    }
  }
  ElseIf ($1 == !Help) || ($1 == .Help) || ($1 == !Commands) || ($1 == .Commands) {
    if ($2 == !instructions) || ($2 == instructions) { .notice $Nick $left !Instructions will display the registration instructions set by the Tournament Host for the tournament. $right }
    elseif ($2 == !rules) || ($2 == rules) { .notice $Nick $left !Rules will display any Restrictions or Bans, the Time Limit, and the Match Type of the Tournament. $right }
    elseif ($2 == !prize) || ($2 == prize) { .notice $Nick $left !Prize will display any prize of the Tournament. $right }
    elseif ($2 == !opponent) || ($2 == opponent) { .notice $Nick $left !Opponent will display your opponent in the Tournament brackets so you do not have to search the screen for him or her. $right }
    elseif ($2 == !remaining) || ($2 == remaining) { .notice $Nick $left !Remaining will display the remaining matches or pairings of people still dueling. $right }
    elseif ($2 == !Timer) || ($2 == .Timer) { .notice $Nick $left !Timer will display the time remaining in the current round of the Tournament. $right }
    elseif ($2 == !loss) || ($2 == loss) { .notice $Nick $left !Loss will remove you from the Tournament and declare your opponent the winner instantly. $right }
    elseif ($2 == !win) || ($2 == win) { .notice $Nick $left !Win will not declare you the winner, it will simply send a message to the Tournament Host notifying him/her you won. $right }
    elseif ($2 == !credits) || ($2 == credits) { .notice $Nick $left !Credits will display information about the creator and the bot version. It will also give a link to where you can download the bot for yourself. $right }
    else { 
      If (!$Timer(HelpCommand).secs) {
        Msg %Tournament.Channel $left Commands you can use: !Instructions, !Rules, !Prize, !Opponent, !Ranking, !Matches, !Timer, !Loss, !Win, !Dropout, and !Credits. For a more in depth description of these commands, type !Help <!command> $right 
        .TimerHelpCommand 1 15 .TimerHelpCommand off
      }
    }
  }
  ElseIf ($1 == !Prize) || ($1 == .Prize) {
    If (!$Timer(PrizeCommand).secs) {
      Msg %Tournament.Channel $left The current prize for this tournament is: %Prize $right
      .TimerPrizeCommand 1 15 .TimerPrizeCommand off
    }
  }
  ElseIf ($1 == !Instructions) || ($1 == .Instructions) || ($1 == !Instr) || ($1 == .Instr) {
    If (!$Timer(InstrCommand).secs) {
      Msg %Tournament.Channel $left %Instructions $right
      .TimerInstrCommand 1 15 .TimerInstrCommand off
    }
  }
  ElseIf ($1 == !Timer) || ($1 == ..Timer) || ($1 == !Time) || ($1 == .Time) {
    If (!$Timer(.TimerCommand).secs) {
      If ($Timer(Bracket).secs > 0) {
        Msg %Tournament.Channel $left Time before the next round: $getTimeLeft $+ . $right
      }
      Else {
        Msg %Tournament.Channel $left There is no bracket Timer active. $right
      }
      .Timer.TimerCommand 1 15 .Timer.TimerCommand off
    }
  }
  ElseIf ($1 == !Rules) || ($1 == .Rules) {
    If (!$Timer(RulesCommand).secs) {
      Msg %Tournament.Channel $left Rules: %Rules Bans: %BannedCards Match Type: %MatchType Time Limit: %TimeLimit minutes. $right
      .TimerRulesCommand 1 15 .TimerRulesCommand off
    }
  }
  ElseIf ($1 == !Remaining) || ($1 == .Remaining) || ($1 == !Matches) || ($1 == .Matches) {
    If (!$Timer(RemainingCommand).secs) {
      If ($Read(brackets.txt) == $Null) { 
        Msg %Tournament.Channel $left There are no more remaining matches. $right
        .TimerRemainingCommand 1 60 .TimerRemainingCommand off
      }
      Elseif ($lines(brackets.txt) >= 8) {
        .notice $Nick $left Please wait for more people to finish their matches before checking the remaining ones. There are currently $lines(brackets.txt) unfinished matches. $right
      }
      Else { 
        Msg %Tournament.Channel $left 10Remaining Matches $right
        Var %Count = 1
        While ($Read(brackets.txt, %Count)) {
          Msg %Tournament.Channel $left $+(10, %Count, .)  $Read(brackets.txt, %Count) $right
          Inc %Count
        }
        .TimerRemainingCommand 1 60 .TimerRemainingCommand off
      }
    }
  }
  ElseIf (($1 == !Register) || ($1 == .Register)) {

    If ($findNick($Nick, listing.txt)) {
      notice $Nick $left You are already registered. $right
    }
    elseIf (%Tournament.isOn == On) && ($Nick ison %Tournament.Channel) {
      If (On isin %Registration.isOn) {
        notice $Nick $left You have registered for the tournament. Please wait for the tournament to begin. $right
        addToListing $Nick 0 0 10
        Mode %Tournament.Channel +v $Nick
      }

    }
  }
  Elseif ($1 == !Opponent) || ($1 == .Opponent) {
    .notice $Nick $left $iif($getOpponent($Nick), $getOpponent($Nick) is your opponent in these brackets.,You have no opponent in these brackets.) $right
  }
  ElseIf ($1 == !Win) || ($1 == .Win) || ($1 == !Won) || ($1 == .Won) {
    If ($findNick($Nick, listing.txt)) && ($Read(brackets.txt,w,$+(*,$Nick,*))) {
      .notice $Nick $left Please have your opponent $getOpponent($Nick) report his/her loss by typing: !loss If he/she cannot, send a PM to the tournament host $me $right
    }
    ElseIf ($findNick($Nick, listing.txt)) {
      .notice $Nick $left You have already been given a win/loss. Sit tight and wait for everyone else to finish. $right
    }
  }
  ElseIf ($1 == !Loss) || ($1 == .Loss) || ($1 == !Lose) || ($1 == .Lose) || ($1 == !Lost) || ($1 == .Lost) {
    If ($findNick($Nick, listing.txt)) && ($Read(brackets.txt,w,$+(*,$Nick,*))) {
      If (%Swiss.isOn == On) {
        Var %PersonData = $deltok($Read(listing.txt, $findNick($nick, listing.txt)),1,32)
        If (%PersonData) && ($calc($gettok(%PersonData,1,32) + $gettok(%PersonData,2,32)) >= %Current.Round) {
          .notice $Nick $left You have already reported your loss. $right
          Halt
        }
      }
      declare_loser $Nick
    }
    ElseIf ($findNick($Nick, listing.txt)) {
      .notice $Nick $left You have already been given a win/loss. Sit tight and wait for everyone else to finish. $right
    }
  }
  ElseIf ($1 == !Rank) || ($1 == .Rank) || ($1 == !Ranking) || ($1 == .Ranking) {
    If (%Swiss.isOn != On) { Halt }
    sortRankings
    If ($2) {
      Var %PersonData = $deltok($Read(listing.txt, $findNick($2, listing.txt)),1,32)
      If (%PersonData) {
        .notice $Nick $left $2 is currently ranked10 $Readn out of $lines(listing.txt) people with a score of:10 $gettok(%PersonData,1,32) $+ - $+ $gettok(%PersonData,2,32) with10 $gettok(%PersonData,3,32) extra points. $right
      }
    }
    Else {
      Var %PersonData = $deltok($Read(listing.txt, $findNick($Nick, listing.txt)),1,32)
      If (%PersonData) {
        .notice $Nick $left You are currently ranked10 $Readn out of $lines(listing.txt) people with a score of:10 $gettok(%PersonData,1,32) $+ - $+ $gettok(%PersonData,2,32) with10 $gettok(%PersonData,3,32) extra points. $right
      }
    }
  }
  ElseIf ($1 == !Top) || ($1 == .Top) || ($1 == !TopRanking) || ($1 == .TopRanking) {
    If (%Swiss.isOn != On) || ($Timer(TopCommand).secs)  { Halt }

    sortRankings
    If ($2 isnum 1-8) {
      Var %Count = 1
      Msg %Tournament.Channel $left 10Top $2 Rankings $right
      While (%Count < $calc($2 + 1)) && ($Read(listing.txt, %Count) != $Null) {
        Msg %Tournament.Channel $left $+(10, %Count, .)  $gettok($Read(listing.txt, %Count),1,32) 10 $+ $gettok($Read(listing.txt, %Count),2,32) $+ - $+ $gettok($Read(listing.txt, %Count),3,32) with10 $gettok($Read(listing.txt, %Count),4,32)  extra points. $right
        Inc %Count
      }
      .TimerTopCommand 1 30 .TimerRemainingCommand off
    }
  }
  ElseIF ($1 == !Dropout) || ($1 == .Dropout) {
    If ($findNick($Nick, listing.txt)) {
      removeFromListing $Nick
      Msg %Tournament.Channel $left $Nick has dropped out of the tournament. $right
    }
    If (!$findNick($Nick, losers.txt)) {
      declare_loser $Nick
    }
    If (%Swiss.isOn == On || %Swiss.isOn == Dbl) {
      Mode %Tournament.Channel +v $getOpponent($Nick)
    }
  }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; ALIASES ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; $1 = Nick
;; $2 = File
alias findNick {
  Var %Count = 1
  While ($gettok($read($2,%Count),1,32) != $1) && (%Count <= $lines($2)) {
    Inc %Count
  }
  return $iif(%Count > $lines($2), 0, %Count)
}
alias -l updateBigButton {
  If (%BigButton.state == 1) {
    /did -ra bottomatic 20 Turn on the tournament script.
  }
  Elseif (%BigButton.state == 2) {
    /did -ra bottomatic 20 Open registration. $iif($Timer(Bracket).secs,Time remaining: $getTimeLeft)
  }
  Elseif (%BigButton.state == 3) {
    /did -ra bottomatic 20 Close registration and silence channel. $iif($Timer(Bracket).secs,Time remaining: $getTimeLeft)
  }
  Elseif (%BigButton.state == 4) {
    /did -ra bottomatic 20 Display rules for round %Current.Round $+ . $iif($Timer(Bracket).secs,Time remaining: $getTimeLeft)
  }
  Elseif (%BigButton.state == 5) {
    /did -ra bottomatic 20 Create round %Current.Round brackets. $iif($Timer(Bracket).secs,Time remaining: $getTimeLeft)
  }
  Elseif (%BigButton.state == 6) {
    /did -ra bottomatic 20 Display bracket Timer. Time remaining: $getTimeLeft
    If (!$Timer(Bracket).secs) {
      Set %BigButton.state 7
    }
  }
  If (%BigButton.state == 7) {
    /did -ra bottomatic 20 Begin the next round and silence channel.
    If (!$read(listing.txt,2)) {
      Set %BigButton.state 8
    }
  }
  If (%BigButton.state == 8) {
    /did -ra bottomatic 20 End the tournament.
    If ($Timer(TourneyEnd)) { } 
    Else {
      .TimerTourneyEnd 1 300 ResetTournament
    }
  }
}

alias -l ResetTournament {
  Write -c brackets.txt
  .TimerBracket off
  bottomatic_mass_remove
  Set %Current.Round 1
  Set %Tournament.isOn Off
  Set %Registration.isOn Off
  Set %Swiss.isOn Off
  Set %BigButton.state 1

  If ($dialog(bottomatic)) {
    showDialogBrackets 1
    /did -ra bottomatic 26 %Current.Round
    /did -ra bottomatic 11 %Tournament.isOn
    /did -ra bottomatic 12 %Registration.isOn
    /did -ra bottomatic 13 %Swiss.isOn
    updateBigButton
  }

  Msg %Tournament.Channel $left The tournament has automatically closed. $right
}

;; $1 = Optional name of person
alias -l updatePersonStatus {
  If ($1) { /did -ra bottomatic 51 $1 }
  Var %PersonData
  If ($didwm(bottomatic,23,$did(51))) {
    Set %PersonData $deltok($Read(ListingWas.txt, $findNick($did(51), ListingWas.txt)),1,32)
  }
  Elseif ($didwm(bottomatic,3,$did(51))) {
    Set %PersonData $deltok($Read(listing.txt, $findNick($did(51), listing.txt)),1,32)
  }
  If (%PersonData) {
    /did -ra bottomatic 36 $gettok(%PersonData,1,32)
    /did -ra bottomatic 37 $gettok(%PersonData,2,32)
    /did -ra bottomatic 38 $gettok(%PersonData,3,32)
  }
  Else {
    /did -ra bottomatic 36 -
    /did -ra bottomatic 37 -
    /did -ra bottomatic 38 -
  }
}

;; $1 = nick of winner
alias -l declare_winner {
  Var %Winner = $1
  Var %Loser = $getOpponent($1)
  If (%Winner) {
    If (true) {
      Msg %Tournament.Channel $left %Winner has defeated %Loser $right
    }
    Else {
      Msg %Tournament.Channel $left %Winner has won! $right
    }
    If (%Winner ison %Tournament.Channel) { Mode %Tournament.Channel +v %Winner }
    Var %Count = 1
    while ($Read(brackets.txt, %Count)) {
      if ($gettok($Read(brackets.txt, %Count),1,32) == %Winner) || ($gettok($Read(brackets.txt, %Count),1,32) == %Loser) {
        Write -dl $+ $Readn brackets.txt
        If ($dialog(bottomatic)) { showDialogBrackets $left($did(bottomatic,77), -1) }
        If ($Read(brackets.txt) == $Null) && ($getTimeLeft > 0) {
          /beep
          .TimerBracket off
          Echo $active $left .notice: All matches have finished in10 %Tournament.Channel before the time limit ended. $right
        }
        /break
      }
      Inc %Count
    }

    If (%Swiss.isOn == On || %Swiss.isOn == Dbl) {
      Var %WinnerData
      Var %LoserData
      If ($findNick(%Winner, listing.txt)) { Set %WinnerData $deltok($Read(listing.txt, $findNick(%Winner, listing.txt)),1,32) } 
      ElseIf ($findNick(%Winner, ListingWas.txt)) { Set %WinnerData $deltok($Read(ListingWas.txt, $findNick(%Winner, ListingWas.txt)),1,32) }
      Else { Set %WinnerData 0 0 10 }
      If ($findNick(%Loser, listing.txt)) { Set %LoserData $deltok($Read(listing.txt, $findNick(%Loser, listing.txt)),1,32) }
      ElseIf ($findNick(%Loser, ListingWas.txt)) { Set %LoserData $deltok($Read(ListingWas.txt, $findNick(%Loser, ListingWas.txt)),1,32) }
      Else { Set %LoserData 0 0 10 }

      If ($findNick(%Winner, listing.txt)) { 
        Write -l $+ $findNick(%Winner, listing.txt) listing.txt %Winner $calc($gettok(%WinnerData,1,32) + 1) $gettok(%WinnerData,2,32) $calc($gettok(%WinnerData,3,32) + $gettok(%LoserData,1,32))
      }
      ElseIf ($findNick(%Winner, ListingWas.txt)) { 
        Write -l $+ $findNick(%Winner, ListingWas.txt) ListingWas.txt %Winner $calc($gettok(%WinnerData,1,32) + 1) $gettok(%WinnerData,2,32) $calc($gettok(%WinnerData,3,32) + $gettok(%LoserData,1,32))
      }
      If ($findNick(%Loser, listing.txt)) { 
        Write -l $+ $findNick(%Loser, listing.txt) listing.txt %Loser $gettok(%LoserData,1,32) $calc($gettok(%LoserData,2,32) + 1) $calc($gettok(%LoserData,3,32) - $gettok(%WinnerData,2,32))
      }
      ElseIf ($findNick(%Loser, ListingWas.txt)) { 
        Write -l $+ $findNick(%Loser, ListingWas.txt) ListingWas.txt %Loser $gettok(%LoserData,1,32) $calc($gettok(%LoserData,2,32) + 1) $calc($gettok(%LoserData,3,32) - $gettok(%WinnerData,2,32))
      }
      If (%Loser ison %Tournament.Channel) { 
        If (%Swiss.IsOn == On || (%Swiss.IsOn == Dbl && $gettok(%loserdata, 2, 32) <= 0)) {
          If (%Loser ison %Tournament.Channel) { 
            If (%Swiss.IsOn == On) .notice %Loser $left This is a Swiss Style tournament; you are not eliminated if you lose. Stay put. $right 
            else .notice %Loser $left This is a Double Elimination tournament; you are not eliminated if you lose the first time. Stay put. $right 
            Mode %Tournament.Channel +v %Loser
          }
        }
        Else {
          If (%Loser ison %Tournament.Channel) { .notice %Loser $left Please put a |W| tag on your name to watch or /part $right }
          Write losers.txt %Loser
          If ($findNick(%Winner, losers.txt)) {
            Write -dl $+ $findNick(%Winner, losers.txt) losers.txt
          }
          removeFromListing %Loser

        }
        sortRankings
      }
      Else {
        If (%Loser ison %Tournament.Channel) { .notice %Loser $left Please put a |W| tag on your name to watch or /part $right }
        Write losers.txt %Loser
        If ($findNick(%Winner, losers.txt)) {
          Write -dl $+ $findNick(%Winner, losers.txt) losers.txt
        }
        removeFromListing %Loser
      }
    }
  }
}
;; $1 = nick of loser
alias -l declare_loser {
  Var %Loser = $1
  Var %Winner = $getOpponent($1)
  If (%Loser) {
    If (true) {
      Msg %Tournament.Channel $left %Winner has defeated %Loser $right
      If (%Winner ison %Tournament.Channel) { Mode %Tournament.Channel +v %Winner }
    }
    Else {
      Msg %Tournament.Channel $left %Loser has taken a loss! $right
    }
    Var %Count = 1
    while ($Read(brackets.txt, %Count)) {
      if ($gettok($Read(brackets.txt, %Count),1,32) == %Winner) || ($gettok($Read(brackets.txt, %Count),1,32) == %Loser) {
        Write -dl $+ $Readn brackets.txt
        If ($dialog(bottomatic)) { showDialogBrackets $left($did(bottomatic,77), -1) }
        If ($Read(brackets.txt) == $Null) && ($getTimeLeft > 0) {
          /beep
          .TimerBracket off
          Echo $active $left .notice: All matches have finished in10 %Tournament.Channel before the time limit ended. $right
        }
        /break
      }
      Inc %Count
    }

    If (%Swiss.isOn == On || %Swiss.isOn == Dbl) {
      Var %WinnerData
      Var %LoserData
      If ($findNick(%Winner, listing.txt)) { Set %WinnerData $deltok($Read(listing.txt, $findNick(%Winner, listing.txt)),1,32) } 
      ElseIf ($findNick(%Winner, ListingWas.txt)) { Set %WinnerData $deltok($Read(ListingWas.txt, $findNick(%Winner, ListingWas.txt)),1,32) }
      Else { Set %WinnerData 0 0 10 }
      If ($findNick(%Loser, listing.txt)) { Set %LoserData $deltok($Read(listing.txt, $findNick(%Loser, listing.txt)),1,32) }
      ElseIf ($findNick(%Loser, ListingWas.txt)) { Set %LoserData $deltok($Read(ListingWas.txt, $findNick(%Loser, ListingWas.txt)),1,32) }
      Else { Set %LoserData 0 0 10 }


      If ($findNick(%Winner, listing.txt)) { 
        Write -l $+ $findNick(%Winner, listing.txt) listing.txt %Winner $calc($gettok(%WinnerData,1,32) + 1) $gettok(%WinnerData,2,32) $calc($gettok(%WinnerData,3,32) + $gettok(%LoserData,1,32))
      }
      ElseIf ($findNick(%Winner, ListingWas.txt)) { 
        Write -l $+ $findNick(%Winner, ListingWas.txt) ListingWas.txt %Winner $calc($gettok(%WinnerData,1,32) + 1) $gettok(%WinnerData,2,32) $calc($gettok(%WinnerData,3,32) + $gettok(%LoserData,1,32))
      }
      If ($findNick(%Loser, listing.txt)) { 
        Write -l $+ $findNick(%Loser, listing.txt) listing.txt %Loser $gettok(%LoserData,1,32) $calc($gettok(%LoserData,2,32) + 1) $calc($gettok(%LoserData,3,32) - $gettok(%WinnerData,2,32))
      }
      ElseIf ($findNick(%Loser, ListingWas.txt)) { 
        Write -l $+ $findNick(%Loser, ListingWas.txt) ListingWas.txt %Loser $gettok(%LoserData,1,32) $calc($gettok(%LoserData,2,32) + 1) $calc($gettok(%LoserData,3,32) - $gettok(%WinnerData,2,32))
      }
      echo -a $gettok(%loserdata, 2, 32)
      If (%Swiss.IsOn == On || (%Swiss.IsOn == Dbl && $gettok(%loserdata, 2, 32) <= 0)) {
        If (%Loser ison %Tournament.Channel) { 
          If (%Swiss.IsOn == On) .notice %Loser $left This is a Swiss Style tournament; you are not eliminated if you lose. Stay put. $right 
          else .notice %Loser $left This is a Double Elimination tournament; you are not eliminated if you lose the first time. Stay put. $right 
          Mode %Tournament.Channel +v %Loser
        }
      }
      Else {
        If (%Loser ison %Tournament.Channel) { .notice %Loser $left Please put a |W| tag on your name to watch or /part $right }
        Write losers.txt %Loser
        If ($findNick(%Winner, losers.txt)) {
          Write -dl $+ $findNick(%Winner, losers.txt) losers.txt
        }
        removeFromListing %Loser
      }
      sortRankings
    }
    Else {
      If (%Loser ison %Tournament.Channel) { .notice %Loser $left Please put a |W| tag on your name to watch or /part $right }
      Write losers.txt %Loser
      If ($findNick(%Winner, losers.txt)) {
        Write -dl $+ $findNick(%Winner, losers.txt) losers.txt
      }
      removeFromListing %Loser
    }
  }
}
alias -l bottomatic_mass_devoice {
  Var %Count = 1
  Var %MassStore = $chr(32)
  While ($Read(listing.txt, %Count) != $Null) {
    Set %MassStore $addtok(%MassStore,$gettok($Read(listing.txt, %Count),1,32),32)
    If ($numtok(%MassStore,32) == 6) {
      Mode %Tournament.Channel -vvvvvv $gettok(%MassStore,1,32) $gettok(%MassStore,2,32) $gettok(%MassStore,3,32) $gettok(%MassStore,4,32) $gettok(%MassStore,5,32) $gettok(%MassStore,6,32)
      Set %MassStore $chr(32)
    } 
    Inc %Count
  }
  If ($numtok(%MassStore,32) > 0) {
    Mode %Tournament.Channel -vvvvvv $gettok(%MassStore,1,32) $gettok(%MassStore,2,32) $gettok(%MassStore,3,32) $gettok(%MassStore,4,32) $gettok(%MassStore,5,32) $gettok(%MassStore,6,32)
  }
}
alias -l bottomatic_mass_add {
  Var %Count = 1
  Var %Person = $Nick(%Tournament.Channel,%Count)
  While (%Person) {
    If (!$findNick(%Person, listing.txt)) && (($Left(%Person, 3) == |H|) || ($Left(%Person, 3) == |F|) || ($Left(%Person, 3) == |C|)) {
      addToListing %Person 0 0 10
    }
    Inc %Count
    Set %Person $Nick(%Tournament.Channel,%Count)
  }
}
alias -l bottomatic_mass_remove {
  While ($Read(listing.txt,1)) {
    removeFromListing $gettok($Read(listing.txt,1),1,32)
  }
  While ($Read(ListingWas.txt,1)) {
    removeFromListingWas $gettok($Read(ListingWas.txt,1),1,32)
  }
}

alias -l createBrackets {
  Write Firewall.txt
  Write Host.txt
  Write Hamachi.txt
  Write DisplayBrackets.txt
  Var %Count = 1
  While ($Read(listing.txt, %Count) != $Null) {
    Write $iif($Left($Read(listing.txt, %Count), 3) == |F|,Firewall.txt,$iif($Left($Read(listing.txt, %Count), 3) == |H|,Host.txt,Hamachi.txt)) $gettok($Read(listing.txt, %Count),1,32)
    Inc %Count
  }

  Write -c losers.txt
  Write -c brackets.txt
  Write -c DisplayBrackets.txt
  Var %Challenger
  Var %Opponent
  Var %MatchNumber = 0

  Write DisplayBrackets.txt $left 10Round %Current.Round Brackets $right
  :BracketStart
  Inc %MatchNumber
  ;; Check Hosts
  If ($Read(Host.txt) != $Null) {
    Set %Challenger $Read(Host.txt) 
    Write -dl $+ $Readn Host.txt

    If ($Read(Firewall.txt) != $Null) {
      Set %Opponent $Read(Firewall.txt)
      Write -dl $+ $Readn Firewall.txt
    }
    ElseIf ($Read(Hamachi.txt) != $Null) && ($lines(Host.txt) >= $lines(Hamachi.txt)) {
      Set %Opponent $Read(Hamachi.txt)
      Write -dl $+ $Readn Hamachi.txt
    }
    ElseIf ($Read(Host.txt) != $Null) {
      Set %Opponent $Read(Host.txt) 
      Write -dl $+ $Readn Host.txt
    }
    Else {
      If ($Read(Hamachi.txt) != $Null) {
        Set %Opponent $Read(Hamachi.txt)
        Write -dl $+ $Readn Hamachi.txt
      }
      Else {
        Write DisplayBrackets.txt $left 10 %MatchNumber $+ .  %Challenger 10gets a BYE! $right
        If (%Swiss.isOn != Off) {
          Var %PersonData = $deltok($Read(listing.txt, $findNick(%Challenger, listing.txt)),1,32)
          If (%PersonData) {
            Write -l $+ $findNick(%Challenger, listing.txt) listing.txt %Challenger $calc($gettok(%PersonData,1,32) + 1) $gettok(%PersonData,2,32) $gettok(%PersonData,3,32)
            sortRankings
          }
        }
        .Timer 1 10 Mode %Tournament.Channel +v %Challenger
        Goto BracketStart
      }
    }
    Write DisplayBrackets.txt  $left 10 %MatchNumber $+ .  %Challenger  10vs.  %Opponent $right
    Write brackets.txt %Challenger vs. %Opponent
    Goto BracketStart
  }
  ;; Check Hamachi
  ElseIf ($Read(Hamachi.txt) != $Null) { 
    Set %Challenger $Read(Hamachi.txt) 
    Write -dl $+ $Readn Hamachi.txt

    If ($Read(Hamachi.txt) == $Null) {
      If ($Read(Firewall.txt) == $Null) {
        Write DisplayBrackets.txt $left 10 %MatchNumber $+ .  %Challenger 10gets a BYE! $right
        If (%Swiss.isOn == On) {
          Var %PersonData = $deltok($Read(listing.txt, $findNick(%Challenger, listing.txt)),1,32)
          If (%PersonData) {
            Write -l $+ $findNick(%Challenger, listing.txt) listing.txt %Challenger $calc($gettok(%PersonData,1,32) + 1) $gettok(%PersonData,2,32) $gettok(%PersonData,3,32)
            sortRankings
          }
        }
        .Timer 1 10 Mode %Tournament.Channel +v %Challenger
        Goto BracketStart
      }
      Else { 
        Set %Opponent $Read(Firewall.txt)
        Write -dl $+ $Readn Firewall.txt
      }
    }
    Else { 
      Set %Opponent $Read(Hamachi.txt)
      Write -dl $+ $Readn Hamachi.txt
    }
    Write DisplayBrackets.txt  $left 10 %MatchNumber $+ .  %Challenger  10vs.  %Opponent $right
    Write brackets.txt %Challenger vs. %Opponent
    Goto BracketStart
  }
  ;; Check Firewalls
  ElseIf ($Read(Firewall.txt) != $Null) { 
    Set %Challenger $Read(Firewall.txt)
    Write -dl $+ $Readn Firewall.txt

    If ($Read(Firewall.txt) == $Null) {
      Write DisplayBrackets.txt $left 10 %MatchNumber $+ .  %Challenger 10gets a BYE! $right
      If (%Swiss.isOn == On) {
        Var %PersonData = $deltok($Read(listing.txt, $findNick(%Challenger, listing.txt)),1,32)
        If (%PersonData) {
          Write -l $+ $findNick(%Challenger, listing.txt) listing.txt %Challenger $calc($gettok(%PersonData,1,32) + 1) $gettok(%PersonData,2,32) $gettok(%PersonData,3,32)
          sortRankings
        }
      }
      .Timer 1 10 Mode %Tournament.Channel +v %Challenger
    }
    Else { 
      Set %Opponent $Read(Firewall.txt)
      Write -dl $+ $Readn Firewall.txt
      Write DisplayBrackets.txt $left 10 %MatchNumber $+ .  %Challenger  10vs.  %Opponent $right
      Write brackets.txt %Challenger vs. %Opponent
    }
    Goto BracketStart
  }
  .Play %Tournament.Channel DisplayBrackets.txt 300
  .Remove Firewall.txt
  .Remove Host.txt
  .Remove Hamachi.txt
  .TimerBracket 1 $calc((%TimeLimit)*60+10) bracket.TimerEnded
  .TimerRemainingCommand 1 60 .TimerRemainingCommand off
}
alias -l bracket.TimerEnded {
  Echo $active $left The bracket Timer for round %Current.Round in %Tournament.Channel has ended. $right
  .notice %Tournament.Channel $left 4Time is up for round %Current.Round $+ . Please report now if you haven't done so already. $right
}

alias -l getTimeLeft { return $duration($Timer(Bracket).secs) }
alias -l getRating { return $iif($calc(%H - %F - (%C - $int($calc(%C / 2)) * 2)) > 0,Good!,$iif($calc(%H - %F - (%C / 2 - $int($calc(%C / 2)) * 2)) < 0,Poor,Fair)) }

;; $1 = Nick to add
;; $2 = Wins
;; $3 = Losses
;; $4 = Tie Points
alias addToListing {
  If (!$findNick($1, listing.txt)) {
    Write listing.txt $1 $2 $3 $4
    If ($Left($1, 3) == |F|) { 
      Inc %F 
      If ($dialog(bottomatic)) {
        /did -ra bottomatic 15 %F
        /did -ra bottomatic 19 $calc(%H + %F + %C)
        /did -ra bottomatic 27 -- $getRating --
      }
    }
    Elseif ($Left($1, 3) == |H|) { 
      Inc %H 
      If ($dialog(bottomatic)) {
        /did -ra bottomatic 14 %H
        /did -ra bottomatic 19 $calc(%H + %F + %C)
        /did -ra bottomatic 27 -- $getRating --
      }
    }
    Elseif ($Left($1, 3) == |C|) { 
      Inc %C 
      If ($dialog(bottomatic)) {
        /did -ra bottomatic 16 %C
        /did -ra bottomatic 19 $calc(%H + %F + %C)
        /did -ra bottomatic 27 -- $getRating --
      }
    }
    If ($dialog(bottomatic)) && (!$didwm(bottomatic,3,$1)) {
      /did -a bottomatic 3 $1
    }
  }
}

;;  $1 = Nick to remove
alias removeFromListing {
  If ($findNick($1, listing.txt)) {
    Write -dl $+ $findNick($1, listing.txt) listing.txt
    If ($Left($1, 3) == |F|) { 
      Dec %F 
      If ($dialog(bottomatic)) {
        /did -ra bottomatic 15 %F
        /did -ra bottomatic 19 $calc(%H + %F + %C)
        /did -ra bottomatic 27 -- $getRating --
      }
    }
    Elseif ($Left($1, 3) == |H|) { 
      Dec %H 
      If ($dialog(bottomatic)) {
        /did -ra bottomatic 14 %H
        /did -ra bottomatic 19 $calc(%H + %F + %C)
        /did -ra bottomatic 27 -- $getRating --
      }
    }
    Elseif ($Left($1, 3) == |C|) { 
      Dec %C 
      If ($dialog(bottomatic)) {
        /did -ra bottomatic 16 %C
        /did -ra bottomatic 19 $calc(%H + %F + %C)
        /did -ra bottomatic 27 -- $getRating --
      }
    }
    If ($dialog(bottomatic)) && ($didwm(bottomatic,3,$1)) {
      /did -d bottomatic 3 $didwm(bottomatic,3,$1) 
    }
  }
  If ($findNick($1, ListingWas.txt)) {
    removeFromListingWas $1
  }
}

alias addToListingWas {
  If (!$findNick($1, ListingWas.txt)) {
    Write ListingWas.txt $1-
    If ($dialog(bottomatic)) && (!$didwm(bottomatic,23,$1)) {
      /did -a bottomatic 23 $1
    }
  }
}
;;  $1 = Nick to remove
alias removeFromListingWas {
  If ($findNick($1, ListingWas.txt)) {
    Write -dl $+ $findNick($1, ListingWas.txt) ListingWas.txt
    If ($dialog(bottomatic)) && ($didwm(bottomatic,23,$1)) {
      /did -d bottomatic 23 $didwm(bottomatic,23,$1) 
    }
  }
  Mode %Tournament.Channel -I $1
}

;; $1 = Nick of other opponent
alias -l getOpponent {
  Var %Count = 1
  while ($Read(brackets.txt, %Count)) {
    if ($gettok($Read(brackets.txt, %Count),1,32) == $1) { return $gettok($Read(brackets.txt, %Count),3,32) }
    elseif ($gettok($Read(brackets.txt, %Count),3,32) == $1) { return $gettok($Read(brackets.txt, %Count),1,32) }
    Inc %Count
  }
  return $Null
}

alias -l sortRankings {
  Var %Count = 1
  Var %MaxIndex

  While (%Count < $lines(listing.txt)) {
    Set %MaxIndex %Count
    Var %Next = $calc(%Count + 1)
    While (%Next < $calc($lines(listing.txt) + 1)) {
      Var %Line = $Read(listing.txt, %Next)
      Var %LineMax = $Read(listing.txt, %MaxIndex)
      If ($calc($gettok(%Line,2,32) * 100 - $gettok(%Line,3,32) * 10 + $gettok(%Line,4,32)) > $calc($gettok(%LineMax,2,32) * 100 - $gettok(%LineMax,3,32) * 10 + $gettok(%LineMax,4,32))) {
        Set %MaxIndex %Next
      }
      Inc %Next
    }
    Var %Temp = $Read(listing.txt,%MaxIndex)
    Write -dl $+ %MaxIndex listing.txt
    Write -il $+ %Count listing.txt %Temp
    Inc %Count
  }
}

; $1 = Starting bracket line number. (displays 6 lines starting with the first)
alias -l showDialogBrackets {
  Var %Count = 0
  Var %Line = $Read(brackets.txt, $calc(%Count + $1))
  While (%Count < 6) && (%Line) {
    /did -ra bottomatic $calc(77 + %Count) $calc($1 + %Count) $+ .
    /did -mra bottomatic $calc(89 + %Count) $gettok(%Line,1,32)
    /did -mra bottomatic $calc(95 + %Count) $iif($gettok(%Line,3,32) == a, BYE, $gettok(%Line,3,32))
    /did -ra bottomatic $calc(101 + %Count) Edit
    Inc %Count
    Set %Line $Read(brackets.txt, $calc(%Count + $1))
  }
  If (%Count != 6) {
    While (%Count < 6)  {
      /did -ra bottomatic $calc(77 + %Count) $calc($1 + %Count) $+ .
      /did -mr bottomatic $calc(89 + %Count)
      /did -mr bottomatic $calc(95 + %Count)
      /did -ra bottomatic $calc(101 + %Count) Edit
      Inc %Count
    }
  }
}

alias -l createVariables {
  ;;;;;; Please change the below to fit your preferences ;;;;;;
  Set %Tournament.Channel #xct
  Set %Instructions To REGISTER: Just change your Nick using: "/nick <newname>" Please attach a tag to the beginning. 4|H| if you can host, 4|F| if you cannot, |W| to just watch, and 4|C| if you can use 4Hamachi . You do 4NOT type !register
  Set %Rules September-bans, Advanced Format. LOG EVERYTHING or Screenshot!
  Set %BannedCards OCG (Japanese) decks.
  Set %Prize 1st) 50 XCBux 2nd) 25XCBux
  Set %MatchType Best 2/3
  Set %TimeLimit 45
  ;;;;;; Do not change anything below this line (unless you know what you are doing) ;;;;;;
  Set %Tournament.isOn Off
  Set %Registration.isOn Off
  Set %Swiss.isOn Off
  Set %Current.Round 1
  Set %BigButton.state 1
  Set %ChannelAdvertiseOK 
  Set %H 0
  Set %F 0
  Set %C 0
  Set %BottomaticUser True
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; AUTO_UPDATER ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
on 1:sockopen:checkupdate: {
  sockwrite -n $sockname GET /Bottomatic/update.txt HTTP/1.0
  sockwrite -n $sockname user-agent: Mozilla/??
  sockwrite -n $sockname Connection: Keep-Alive
  sockwrite -n $sockname Content-Type: text/html
  sockwrite -n $sockname Host: arruz.bravehost.com $+ $crlf $+ $crlf
}
on 1:sockread:checkupdate: {
  if ($sockerr > 0) return
  sockread -f %UpdateVersion
  if ($sockbr == 0) return
  if (%UpdateVersion == $null) %UpdateVersion = -
  If ($gettok(%UpdateVersion,1,32) == Bottomatic) {
    .Timer 1 5 sockclose checkupdate
    If ($gettok(%UpdateVersion,3,32) != 1.6.6) {
      /dialog -mvd updatebottomatic updatebottomatic
      /dialog -e bottomatic
      halt
    }
  }
}
on *:DIALOG:updatebottomatic:sclick:2: {
  Run http://www.vyso.org/bottomatic4.mrc
  /dialog -x updatebottomatic updatebottomatic
}



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; DIALOGS ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dialog bottomatic {
  title "BøttømåtiÇ™ 4.1"
  size -1 -1 252 167
  option dbu
  box "Tournament Status", 24, 74 0 90 50
  text "Tournament:", 4, 77 8 33 8
  text %Tournament.isOn, 11, 109 8 14 8, center
  text "Registration:", 5, 77 16 33 8
  text %Registration.isOn, 12, 109 16 14 8, center
  text "Swiss:", 6, 77 24 33 8
  text %Swiss.isOn, 13, 109 24 14 8, center
  text "Current Round:", 25, 77 32 39 8
  text %Current.Round, 26, 115 32 8 8, center
  text "Channel:", 7, 77 40 24 8
  text %Tournament.Channel, 17, 100 40 30 8
  text "Hosters:", 8, 129 8 23 8, right
  text %H, 14, 153 8 8 8, center
  text "Firewall:", 9, 129 16 23 8, right
  text %F, 15, 153 16 8 8, center
  text "Hamachi:", 10, 129 24 23 8, right
  text %C, 16, 153 24 8 8, center
  text "Total:", 18, 134 32 18 8, right
  text "0", 19, 153 32 8 8, center
  text "-- Good --", 27, 130 40 31 8, center
  box "Individual Status", 1, 167 0 83 50
  edit "", 51, 171 8 75 10
  button "Add", 31, 170 28 27 10
  button "Remove", 32, 170 38 27 10
  button "Give Win", 29, 199 28 29 10
  button "Give Loss", 30, 199 38 29 10
  button "Edit", 72, 230 28 17 10
  button "Kick", 73, 230 38 17 10
  text "Wins:", 33, 171 18 15 8
  text "-", 36, 186 18 8 8
  text "Losses:", 34, 195 18 20 8
  text "-", 37, 214 18 8 8
  text "Points:", 35, 222 18 18 8
  text "-", 38, 239 18 8 8
  box "Participant Listings", 21, 2 0 70 106
  list 3, 4 8 66 96, sort size vsbar
  box "Missing from Tournament", 22, 2 107 70 58
  list 23, 4 115 66 48, sort size vsbar
  box "Brackets - Remaining Matches", 2, 74 50 176 92
  button "[ERROR] Please Restart your mIRC client ", 20, 74 145 176 20

  text "1.", 77, 76 59 9 8, center
  text "2.", 78, 76 71 9 8, center
  text "3.", 79, 76 83 9 8, center
  text "4.", 80, 76 95 9 8, center
  text "5.", 81, 76 107 9 8, center
  text "6.", 82, 76 119 9 8, center
  text "vs.", 83, 151 59 9 8, center
  text "vs.", 84, 151 71 9 8, center
  text "vs.", 85, 151 83 9 8, center
  text "vs.", 86, 151 95 9 8, center
  text "vs.", 87, 151 107 9 8, center
  text "vs.", 88, 151 119 9 8, center
  edit "", 89, 86 58 53 10, read autohs
  edit "", 90, 86 70 53 10, read autohs
  edit "", 91, 86 82 53 10, read autohs
  edit "", 92, 86 94 53 10, read autohs
  edit "", 93, 86 106 53 10, read autohs
  edit "", 94, 86 118 53 10, read autohs
  edit "", 95, 160 58 53 10, read autohs
  edit "", 96, 160 70 53 10, read autohs
  edit "", 97, 160 82 53 10, read autohs
  edit "", 98, 160 94 53 10, read autohs
  edit "", 99, 160 106 53 10, read autohs
  edit "", 100, 160 118 53 10, read autohs
  button "Edit", 101, 226 58 21 10
  button "Edit", 102, 226 70 21 10
  button "Edit", 103, 226 82 21 10
  button "Edit", 104, 226 94 21 10
  button "Edit", 105, 226 106 21 10
  button "Edit", 106, 226 118 21 10
  button "Previous", 107, 77 130 37 10
  button "Next", 108, 210 130 37 10
  button "^", 110, 140 58 10 10
  button "^", 111, 140 70 10 10
  button "^", 112, 140 82 10 10
  button "^", 113, 140 94 10 10
  button "^", 114, 140 106 10 10
  button "^", 115, 140 118 10 10
  button "^", 116, 214 58 10 10
  button "^", 117, 214 70 10 10
  button "^", 118, 214 82 10 10
  button "^", 119, 214 94 10 10
  button "^", 120, 214 106 10 10
  button "^", 121, 214 118 10 10

  menu "Tournament", 39
  item "Turn On/Off", 40, 39
  item "Registration On/Off", 41, 39
  item break, 999, 39
  item "Display rules", 44, 39
  item "View/Edit rules", 43, 39
  item break, 999, 39
  item "Change Big Button", 109, 39
  item "Reset Script", 42, 39
  menu "Brackets", 63
  item "Display brackets", 65, 63
  item break, 999, 63
  item "Display bracket Timer", 66, 63
  item "Edit bracket Timer", 67, 63
  menu "Swiss", 68
  item "Turn swiss On/Off", 69, 68
  item "Turn double elim On/Off", 200, 68
  item break, 999, 68
  item "Display top # rankings", 70, 68
  item "Voice top # of people", 71, 68
  menu "Channel", 45
  item "Display how-to-register", 55, 45
  item "Advertise tourney", 54, 45
  item "Invite a person", 53, 45
  item "Set Channel", 46, 45
  item break, 999, 45
  menu "Mute / Unmute", 47, 45
  item "Mute (non-voices cannot speak)", 48, 47
  item "Unmute (non-voices can speak)", 49, 47
  menu "Lock / Unlock", 50, 45
  item "Lock (people cannot join channel)", 28, 50
  item "Unlock (people can join channel)", 52, 50
  menu "Mass", 56
  item "Mass devoice (-v)", 57, 56
  item "Mass register everyone", 58, 56
  item "Mass unregister everyone", 59, 56
  item break, 999, 56
  item "Kick all non-voices", 60, 56
  item "Kick all non-participants", 61, 56
  item "Kick all previous losers", 62, 56
}
;;;;;;;;;; RULES_DIALOG ;;;;;;;;;;
dialog rules_notepad {
  title "View/Edit tournament rules"
  size -1 -1 232 80
  option dbu
  box "Edit the rules and other info below:", 1, 4 1 226 65
  text "Instructions:", 2, 8 9 30 9
  text "Rules:", 3, 8 18 30 9
  text "Bans:", 4, 8 27 30 9
  text "Prize:", 5, 8 36 30 9
  text "Match Type:", 6, 8 45 30 9
  text "Time Limit:", 7, 8 54 30 9
  edit %Instructions, 8, 40 9 188 9, autohs
  edit %Rules, 9, 40 18 188 9, autohs
  edit %BannedCards, 10, 40 27 188 9, autohs
  edit %Prize, 11, 40 36 188 9, autohs
  edit %MatchType, 12, 40 45 188 9, autohs
  edit %TimeLimit, 13, 40 54 188 9, autohs
  button "Apply", 14, 7 68 30 10
  button "Cancel", 15, 40 68 30 10
  button "Load File", 16, 156 68 34 10
  button "Save to File", 17, 193 68 34 10
}
;;;;;;;;;; BIG_BUTTON_DIALOG ;;;;;;;;;;
dialog bigbutton_state {
  title "Change the Big Button state"
  size -1 -1 126 96
  option dbu
  box "Select the new Big Button state:", 1, 2 0 122 84
  radio "Turn on the tournament script.", 2, 7 8 114 10
  radio "Open registration.", 3, 7 17 114 10
  radio "Close registration and silence channel.", 4, 7 26 114 10
  radio Display rules for round %Current.Round $+ ., 5, 7 35 114 10
  radio Create round %Current.Round brackets., 6, 7 44 114 10
  radio "Display bracket Timer.", 7, 7 53 114 10
  radio "Begin the next round and silence channel.", 8, 7 62 114 10
  radio "End the tournament.", 9, 7 71 114 10
  button "Apply", 10, 31 85 29 10
  button "Cancel", 11, 65 85 29 10
}
;;;;;;;;;; UPDATE_BOTTOMATIC_DIALOG ;;;;;;;;;;
dialog updatebottomatic {
  title "BøttømåtiÇ™ Updater"
  size -1 -1 100 46
  option dbu
  text "The Bottomatic script you are using is outdated. Please download the newest version by clicking the button below. It only takes a few seconds!", 1, 1 1 97 30, center
  button "Download Update Now!", 2, 15 32 69 12
}

dialog acronyms {
  title "Acronyms Editor"
  size -1 -1 220 165
  option dbu
  list 1, 1 9 152 141, size
  button "Add Acronym", 2, 1 151 50 12
  button "Delete Acronym", 3, 52 151 50 12
  text "flupScript Acronyms", 4, 2 1 52 8
  check "Acronyms Enabled", 6, 103 151 55 12,
  text "Edit", 7, 156 10 25 8
  edit "", 8, 155 26 63 10
  text "Short Acro", 9, 156 18 27 8
  text "Long Acro", 10, 156 37 25 8
  edit "", 11, 155 46 63 10, autohs
  button "Make Changes", 12, 155 58 37 12

}
on *:dialog:acronyms:init:0:{
  did -m acronyms 8
  did -r acronyms 1
  var %x 1
  while (%x <= $hget(acronyms,0).item) {
    did -a acronyms 1 $gettok($hget(acronyms,%x).item,1,32)
    inc %x
  }
  if (%acronyms.on == $true) {
    did -c acronyms 6
  }
  if (%acronyms.on != $true) {
    did -u acronyms 6
  }
}
on *:dialog:acronyms:sclick:1:{
  if ($did(1).sel != $null) {
    did -ra acronyms 8 $hget(acronyms,$did(1).sel).item
    did -ra acronyms 11 $hget(acronyms,$did(1).sel).data
  }
}
on *:dialog:acronyms:sclick:2:{
  var %acroshort $$?="Short Acronym. (Eg: lol)"
  if ($hget(acronyms,$gettok(%acroshort,1,32)) != $null) { 
    echo -a You already have an acronym for that. Edit it instead.
  }
  else {
    var %acrolong $$?="Long Acronym. (Eg: Laughing out Loud)"
    hadd acronyms $gettok(%acroshort,1,32) %acrolong  
    did -r acronyms 1
    var %x 1
    while (%x <= $hget(acronyms,0).item) {
      did -a acronyms 1 $gettok($hget(acronyms,%x).item,1,32)
      inc %x
    }
  }
}
on *:dialog:acronyms:sclick:3:{
  hdel acronyms $did(1).seltext
  did -r acronyms 1
  did -r acronyms 8
  did -r acronyms 11
  var %x 1
  while (%x <= $hget(acronyms,0).item) {
    did -a acronyms 1 $gettok($hget(acronyms,%x).item,1,32)
    inc %x
  }
}
on *:dialog:acronyms:sclick:6:{
  if ($did(6).state == 1) {
    set %acronyms.on $true
  }
  if ($did(6).state == 0) {
    set %acronyms.on $false
  }
}
on *:dialog:acronyms:sclick:12:{
  hadd acronyms $did(1).seltext $did(11).text
}
on *:input:*:{
  if (%acronyms.on == $true) {
    if ($left($1-,1) != /) && (!$ctrlenter) {
      var %acrotext = $1-
      var %acrotext.send = $1-
      var %acronum = $numtok(%acrotext,32)
      var %acronum2 = 1
      :again
      if (%acronum2 <= %acronum) {
        if ($hget(acronyms,$gettok(%acrotext,%acronum2,32)) != $null) {
          var %1 = $gettok(%acrotext,%acronum2,32))
          var %2 = $hget(acronyms,$gettok(%acrotext,%acronum2,32))
          var %acrotext.send = $reptok(%acrotext.send,%1,%2,1,32)
          inc %acronum2
          goto again
        }
        if ($hget(acronyms,$gettok(%acrotext,%acronum2,32)) == $null) {
          inc %acronum2
          goto again
        }
      }
      msg $active %acrotext.send 
      halt
    }
  }
}
on *:disconnect:{ hsave acronyms acronyms.txt }
alias acro dialog -m acronyms acronyms
menu channel,menubar {
  ..Acronyms:acro
}
