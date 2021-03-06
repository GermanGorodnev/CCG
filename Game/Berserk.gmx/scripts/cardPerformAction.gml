// decrease the mana
if (state == CARD_STATES.DESTROY)
    exit;
     
if (ds_list_empty(actions))
{
    cardDone();
    exit
}
var act = actions[| 0];

var pos = cardGetArrIndexByEnum(act);
if (pos != -1)
    cardChangeMana(-actionsMana[pos]);


if (!canTurn || !actions[| 1])
{
    state = CARD_STATES.DONE_ACTION;
    exit; //WARNING
}

var target = actions[| 2];
var removeStealth = true;
switch (act)
{
    case ACTIONS.ATTACK: // just an attack
        state = CARD_STATES.PERFORM_ACTION
        cardAttack(target, gameGetListByTargetGroup(actions[| 3], target), dmg, atkSpd, -1);
        break;
    case ACTIONS.PASS_THE_TURN:
        cardDone();
        // LUL
        break;
                            /* BATTLECRIES */
    // MIMICS
    case ACTIONS.MIMIC_WILD_BATTLECRY:
    case ACTIONS.MIMIC_TOWN_BATTLECRY:
        state = CARD_STATES.PERFORM_ACTION;
        (cardAttack(target, gameGetListByTargetGroup(actions[| 3], target), dmg, atkSpd, -1)).parent = id;        
        break;
                            /* PASSIVE */
    case ACTIONS.MUSHROOMS_POISON_PASSIVE:
        var dbf = ds_list_create();
        var p = ds_list_create();
        ds_list_add(p, DEBUFFS.POISON, 2, 1);
        ds_list_add(dbf, p); 
        //ds_list_mark_as_list(dbf, 0);
        var a = cardAttack(target, gameGetListByTargetGroup(actions[| 3], target), 0, atkSpd, dbf); 
        a.image_index = 1;
        // - HP
        cardChangeHp(-1);
        break;
                            /* UNIQUE ABILITIES */    
    // KONCHA
    case ACTIONS.KONCHA_HEAL: // healing the card
        state = CARD_STATES.PERFORM_ACTION;
        cardHeal(target, gameGetListByTargetGroup(actions[| 3], target), 2);
        cardDone();
        break;
    case ACTIONS.KONCHA_POISON: // poison the enemy
        state = CARD_STATES.PERFORM_ACTION;
        var dbf = ds_list_create();
        var p = ds_list_create();
        ds_list_add(p, DEBUFFS.POISON, 2, 1);
        ds_list_add(dbf, p); 
        //ds_list_mark_as_list(dbf, 0);
        var s = cardAttack(target, gameGetListByTargetGroup(actions[| 3], target), 0, atkSpd, dbf);
        s.image_index = 3;
        break;
    // LISA
    case ACTIONS.LISA_BACKSTAB:
        state = CARD_STATES.PERFORM_ACTION;
        var a = cardAttack(target, gameGetListByTargetGroup(actions[| 3], target), dmg, atkSpd, -1); 
        a.absolute = true;  
        a.empower = false;  
        a.image_index = 4;
        break;
    // MIMIC WILD
    case ACTIONS.MIMIC_WILD_STUN:
        var dbf = ds_list_create();
        var p = ds_list_create();
        ds_list_add(p, DEBUFFS.STUN, 1);
        ds_list_add(dbf, p); 
        //ds_list_mark_as_list(dbf, 0);
        var ls = gameGetListByTargetGroup(actions[| 3], target);
        var realTarget = cardIndexToPos(target, ls);
        if (realTarget != noone)
        {
            instance_create(realTarget.x, realTarget.y, oInstant);
            var s = cardAttack(target, ls, 0, -1, dbf);
        }    
        break;
    // ARMOR HAMMER
    case ACTIONS.ARMOR_HAMMER_USE:
        state = CARD_STATES.PERFORM_ACTION
        // delete an armor and dead
        var a = cardAttack(target, gameGetListByTargetGroup(actions[| 3], target), 0, atkSpd, -1);
        a.breakArmor = true;
        // and suddenly dead
        cardSetState(CARD_STATES.DESTROY);    
        break;
    // MUSHROOMS
    case ACTIONS.MUSHROOMS_ATTACK_DEATH:
        state = CARD_STATES.PERFORM_ACTION
        cardAttack(target, gameGetListByTargetGroup(actions[| 3], target), dmg, atkSpd, -1);
        // and suddenly dead
        cardSetState(CARD_STATES.DESTROY);    
        break; 
    //JOJN
    case ACTIONS.JOJN_SWORD_STRIKE: // 50% to break armor, 25% to deal true dmg, 25% to miss
        state = CARD_STATES.PERFORM_ACTION
        var luck = actions[| 4];
        if (luck == 0) // break arm
        {
            var a = cardAttack(target, gameGetListByTargetGroup(actions[| 3], target), 0, atkSpd, -1); 
            a.breakArmor = true;    
        }
        else if (luck == 1) // true dmg
        {
            var a = cardAttack(target, gameGetListByTargetGroup(actions[| 3], target), dmg, atkSpd, -1); 
            a.absolute = true;            
        }
        else // jsut miss
        {
            state = CARD_STATES.DONE_ACTION;
        }
        break;
    case ACTIONS.JOJN_IMPACT_OF_THE_DIVINE: // steals the card if all its stats are <= 3
        var s = instance_create(x, y, oJojnImpact);
        s.pl = player;
        s.startPl = player;
        s.target = cardIndexToPos(target, gameGetListByTargetGroup(actions[| 3], target));
        s.parent = id;
        s.speed = atkSpd;
        break;
    // GARGULIA
    case ACTIONS.GARGULIA_BLOCK:
        cardSetBuff(BUFFS.BLOCK, 1);
        cardDone();       
        break;
    case ACTIONS.MANA_PLUS_ONE:
        cardChangeMana(1);
        cardDone();
        break;
    // ARTONIX
    case ACTIONS.ARTONIX_AUTOMAT_FIRE:
        state = CARD_STATES.PERFORM_ACTION
        var group = gameGetListByTargetGroup(actions[| 3], target);
        var bull = cardAttack(target, group, dmg, atkSpd * 2, -1);
        bull.parent = noone;
        bull.image_index = 5;
        var i = 0;
        repeat(2)
        {
            var b = cardAttack(target, group, dmg, atkSpd * 2, -1);
            b.visible = false;
            b.active = false;
            b.alarm[0] = 0.5 * (i + 1) * room_speed;
            b.spd = bull.speed;
            b.speed = 0;
            b.image_index = 5;
            if (i == 0)
                bull.parent = noone;
            i++;
        }
        break;
    // SMEMS
    case ACTIONS.SMEMS_BLESSING:
        var targetId = cardIndexToPos(target, gameGetListByTargetGroup(actions[| 3], target));
        with (targetId)
        {
            cardChangeDmg(2);
            cardChangeArmor(1); 
            cardAddConstantBuff(getFraseLang("bless", -1));           
        }
        cardDone();
        break;
    case ACTIONS.SMEMS_FIREBALL:
        state = CARD_STATES.PERFORM_ACTION
        var a = cardAttack(target, gameGetListByTargetGroup(actions[| 3], target), dmg, atkSpd, -1);
        with (a) {
            sprite_index = sSmemsFireball;
            image_speed = 1;
        }
        break;
    // PORCHANKA
    case ACTIONS.PORCHANKA_CORRUPTION:
        var targetId = cardIndexToPos(target, gameGetListByTargetGroup(actions[| 3], target));
        if (targetId != noone)
        {
        with (targetId)
        {
            cardAddDeathrattle(DEATHRATTLES.CORRUPTION);
            cardChangeHp(-1);
        }
        }
        cardDone();
        break;
    // PECHENKA
        case ACTIONS.COOKIE_DEVOUR:
        state = CARD_STATES.PERFORM_ACTION
        var s = instance_create(x, y, oDevour);
        s.pl = player;
        s.startPl = player;
        s.target = cardIndexToPos(target, gameGetListByTargetGroup(actions[| 3], target));
        s.parent = id;
        s.speed = atkSpd;
        s.dmg = 1;
        s.heal = 2;
        break;  
    // SLIME GOLEM
    case ACTIONS.GOLEM_SLIME_DEVOUR:
        state = CARD_STATES.PERFORM_ACTION
        var s = instance_create(x, y, oDevour);
        s.pl = player;
        s.startPl = player;
        s.target = cardIndexToPos(target, gameGetListByTargetGroup(actions[| 3], target));
        s.parent = id;
        s.speed = atkSpd;
        s.dmg = 2;
        s.heal = 3;
        break;
    // STONE GOLEM
    case ACTIONS.GOLEM_STONE_PRESSURE:
        state = CARD_STATES.PERFORM_ACTION
        var s = instance_create(x, y, oPressure);
        s.pl = player;
        s.target = cardIndexToPos(target, gameGetListByTargetGroup(actions[| 3], target));
        s.startPl = player;
        s.parent = id;
        s.speed = atkSpd;
        s.dmg = 4;
        break;
    case ACTIONS.GOLEM_STONE_LIGHTNING:
        var ls = gameGetListByTargetGroup(actions[| 3], target);
        var realTarget = cardIndexToPos(target, ls);
        if (realTarget != noone)
        {
        with (realTarget)
        {
            cardChangeHp(-3);
            cardChangeArmor(-1);
        }  
        instance_create(realTarget.x, realTarget.y, oLightning);  
        } 
        break;
    //////////////// FAMILY ////////////////////////
    // GOLEM BATYA
    case ACTIONS.GOLEM_BATYA_BLOCK: // 2 turn block
        cardSetBuff(BUFFS.BLOCK, 2);
        cardDone();       
        break;
    // GOLEM MATYA
    case ACTIONS.GOLEM_MATYA_KISS:
        var ls = gameGetListByTargetGroup(actions[| 3], target);
        var realTarget = cardIndexToPos(target, ls);
        if (realTarget != noone)
        {
        with (realTarget)
        {
            cardIncreaseMaxStat(1, "hp");
            cardIncreaseMaxStat(1, "dmg");
            cardAddConstantBuff(getFraseLang("matya", -1));           
        }  
        }
        cardDone();        
        break;
    // GOLEM SON
    case ACTIONS.GOLEM_SON_RAGE:
        // double dmg - 1 hp
        state = CARD_STATES.PERFORM_ACTION
        var a = cardAttack(target, gameGetListByTargetGroup(actions[| 3], target), dmg * 2, atkSpd, -1);
        cardChangeHp(-1);
        break;
    case ACTIONS.GOLEM_SON_GENGAP:
        var amountDad = cardGetCountOnBoard(CARDS.GOLEM_BATYA, cardGetGroup()),
            amountMom = cardGetCountOnBoard(CARDS.GOLEM_MATYA, cardGetGroup());
        if (amountDad > 0 || amountMom > 0)
        {
            cardIncreaseMaxStat(2, "dmg");
            cardAddConstantBuff(getFraseLang("gengap", -1));           
        }
        else
        {
            // fail
        }
        cardDone();
        break;
    // GOLEM CRUSHER
    case ACTIONS.GOLEM_CRUSHER_TRIPLE:
        state = CARD_STATES.PERFORM_ACTION
        var s = instance_create(x, y, oTriple);
        s.pl = player;
        s.startPl = player;
        s.target = cardIndexToPos(target, gameGetListByTargetGroup(actions[| 3], target));
        s.startPl = player;
        s.parent = id;
        s.speed = atkSpd;
        s.dmg = dmg;
        break;
    // SCOUT
    case ACTIONS.SCOUT_TRUE_VISION:
        with (oCardBase)
        {
            if (cardHasBuff(BUFFS.INVISIBILITY, id) != -1)
                cardDeleteBuff(BUFFS.INVISIBILITY);
        }
        cardDone();
        break;
    // SECTANT MAGE
    case ACTIONS.SECTANT_MAGE_MANA:
        var ls = gameGetListByTargetGroup(actions[| 3], target);
        var realTarget = cardIndexToPos(target, ls);
        if (realTarget != noone)
        {
        with (realTarget)
        {
            cardChangeMana(1);
        }  
        }
        cardDone();
        break;
    // UNDERGROUND DEVOURER
    case ACTIONS.UNDER_DEVOURER_DEVOUR:
        // eats adjacent
        var l = instance_position(x - 150, y, oCardBase),
            r = instance_position(x + 150, y, oCardBase);
        if (r != noone)
        {
            cardIncreaseMaxStat(r.hp, "hp");
            cardIncreaseMaxStat(r.dmg, "dmg");
            cardIncreaseMaxStat(r.armor, "armor");
            // NOM NOM
            with (r)
            {
                cardDone();
                cardSetState(CARD_STATES.DESTROY);
            }
        }
        if (l != noone)
        {
            cardIncreaseMaxStat(l.hp, "hp");
            cardIncreaseMaxStat(l.dmg, "dmg");
            cardIncreaseMaxStat(l.armor, "armor");
            // NOM NOM
            with (l)
            {
                cardDone();
                cardSetState(CARD_STATES.DESTROY);
            }
        }
        if (r != noone || l != noone)
        {
            cardAddConstantBuff(getFraseLang("devour", -1));           
        }
        cardDone();
        break;
    // CHEMIST INVENTOR
    case ACTIONS.CHEMIST_INVENTOR_MINI_BOT: // summon a card
        var c = cardSummon(player, CARDS.MINI_BOT, -1);
        cardDone();
        break;
    case ACTIONS.CHEMIST_INVENTOR_TRANSFORM:
        var ls = gameGetListByTargetGroup(actions[| 3], target);
        var realTarget = cardIndexToPos(target, ls);
        var newt = actions[| 4];
        if (realTarget != noone)
        {
        with (realTarget)
        {
            instance_destroy();
            cardDone();
            state = CARD_STATES.DESTROY;
            cardReplace(newt);
            cardClearMemory();
        }
        }
        cardDone();
        break;
    // MINI-BOT
    case ACTIONS.MINI_BOT_SECRET_CODE:
        with (oCardBase)
        {
            if (type == CARDS.MINI_BOT)
            {
                cardChangeDmg(1);
            }
        }
        cardDone();
        break;
    // ARCHER
    case ACTIONS.ARCHER_FIRE_ARROWS:
        cardSetBuff(BUFFS.FIRE_ARROWS, 2);
        cardDone();
        break;
    // CAVALRY    
    case ACTIONS.CAVALRY_REAR:
        var dbf = ds_list_create();
        var p = ds_list_create();
        ds_list_add(p, DEBUFFS.CAVALRY, 2);
        ds_list_add(dbf, p); 
        var ls = gameGetListByTargetGroup(actions[| 3], target);
        var s = cardAttack(target, ls, 0, atkSpd, dbf);    
        cardDone();
        break;   
    // VAPE
    case ACTIONS.VAPE_BATTLECRY:        
        for (var i = -1; i < 2; i++)
        {
            for (var j = -1; j < 2; j++)
            {
                var inst = instance_position(x + i * 134, y + j * 160, oCardBase);
                if (inst == id || inst == noone)
                    continue;
                with (inst)
                    cardSetBuff(BUFFS.INVISIBILITY, -4);
            }
        }
        cardDone();
        break;
    // HELICOPTER
    case ACTIONS.HELI_HELP:
        var cardType = actions[| 2];
        var mult = 1;
        if (player) // enemy
            mult = -1;
        var pos = instance_position(x, y + 160 * mult, oCardBase);
        if (pos != noone || y + 160 * mult > room_height || y + 160 * mult < 0) // it's free
            cardDone();
        else
        {
            // summon a random 0 rarity card
            var p = ds_list_find_index(cardGetGroup(), id);
            var c = cardSummon(player, cardType, p + global.cardsOnBoard / 2);
            cardDone();
        }
        break;
        
    // OFFICER
    case ACTIONS.OFFICER_CASTLING:
        var ls = gameGetListByTargetGroup(actions[| 3], target);
        var realTarget = cardIndexToPos(target, ls);
        if (realTarget != noone)
        {
        var can = true;
        if (!ds_list_empty(realTarget.actions))
        {
            if (realTarget.actions[| 0] != ACTIONS.PASS_THE_TURN)
                can = false;
        }
        if (can)
        {
            var xto = realTarget.x,
                yto = realTarget.y,
                xtar = x,
                ytar = y;
            // change places
            // mine
            state = CARD_STATES.PERFORM_ACTION;
            path_clear_points(cardPath);
            path_set_closed(cardPath, false);                
            path_add_point(cardPath, x, y, 100);
            path_add_point(cardPath, xto, yto, 100);
            path_start(cardPath, 8, path_action_stop, true);
            // placer
            instance_create(xto, yto, oPlaceNotFree);

            // choosen card
            with (realTarget)
            {
                cardClearOurImpacts();
                cardClearImpacts();
                state = CARD_STATES.PERFORM_ACTION;
                path_clear_points(cardPath);
                path_set_closed(cardPath, false);                
                path_add_point(cardPath, x, y, 100);
                path_add_point(cardPath, xtar, ytar, 100);
                path_start(cardPath, 8, path_action_stop, true);
                // placer
                instance_create(xtar, ytar, oPlaceNotFree);            
            }
            var p = ds_list_find_index(cardGetGroup(), id);
            ds_list_replace(cardGetGroup(), p, realTarget);
            ds_list_replace(cardGetGroup(), target, id);
        }
        else
            cardDone();
        }
        else
            cardDone();
        break;
    // GRAVER SUMMON
    case ACTIONS.GRAVER_GRAVE:
        var cardType = actions[| 2];
        if (cardType != -1)
            cardSummon(player, cardType, -1);
        cardDone();
        break;
    // STEALTH_KILLER
    case ACTIONS.STEALTH_KILLER_ST_ATT:
        var ls = gameGetListByTargetGroup(actions[| 3], target);
        var realTarget = cardIndexToPos(target, ls);
        if (realTarget != noone)
        {
            var dd = dmg;
            with (realTarget)
            {
                cardDealDamage(dd, false);
            }  
            if (realTarget.hp <= 0) // dead
            {
                cardSetBuff(BUFFS.INVISIBILITY, -4);
                removeStealth = false;
            }
        } 
        break;
    // NINJA
    case ACTIONS.NINJA_BACKSTAB:
        state = CARD_STATES.PERFORM_ACTION;
        var a = cardAttack(target, gameGetListByTargetGroup(actions[| 3], target), dmg, atkSpd, -1); 
        a.absolute = true;  
        a.empower = false;  
        a.image_index = 4;
        break;
    // FIELD MEDIC
    case ACTIONS.FIELD_MED_H_2:
        cardHeal(target, gameGetListByTargetGroup(actions[| 3], target), 2);
        cardDone();
        break;
    // BATTLE MEDIC
    case ACTIONS.BAT_MED_ATT_POISON_NOT:
        if (mana <= 2)
        {
            // Just attack
            state = CARD_STATES.PERFORM_ACTION;
            cardAttack(target, gameGetListByTargetGroup(actions[| 3], target), dmg, atkSpd, -1);
        }
        else
        {
            state = CARD_STATES.PERFORM_ACTION;
            var dbf = ds_list_create();
            var p = ds_list_create();
            ds_list_add(p, DEBUFFS.POISON, 2, 1);
            ds_list_add(dbf, p); 
            //ds_list_mark_as_list(dbf, 0);
            var s = cardAttack(target, gameGetListByTargetGroup(actions[| 3], target), dmg, atkSpd, dbf);
            s.image_index = 3;
        }
        break;
    case ACTIONS.BAT_MED_H_3:
        cardHeal(target, gameGetListByTargetGroup(actions[| 3], target), 3);
        cardDone();
        break;
    case ACTIONS.BAT_MED_TGH:
        // if we do not have a buff - add one
        if (!cardHasBuff(BUFFS.GREAT_HEAL, id))
        {
            cardSetBuff(BUFFS.GREAT_HEAL, 3);
        }
        cardDone();
        break;
    // MECHANIC
    case ACTIONS.MECHANIC_MECH_HEAL_3:
        cardHeal(target, gameGetListByTargetGroup(actions[| 3], target), 2);
        cardDone();        
        break;
    case ACTIONS.MECHANIC_ATTACK_TRUE_AFTER:
        state = CARD_STATES.PERFORM_ACTION;
        var dbf = ds_list_create();
        var p = ds_list_create();
        ds_list_add(p, DEBUFFS.MECHANIC_ATTACK, 2, 1);
        ds_list_add(dbf, p); 
        //ds_list_mark_as_list(dbf, 0);
        var s = cardAttack(target, gameGetListByTargetGroup(actions[| 3], target), dmg, atkSpd, dbf);        
        break;
    // CAVE SPIDER
    case ACTIONS.CAVE_SPIDER_BITE:
        var ls = gameGetListByTargetGroup(actions[| 3], target);
        var realTarget = cardIndexToPos(target, ls);
        if (realTarget != noone)
        {
            with (realTarget)
            {
                cardChangeDmg(-(dmg - 2));
                cardAddConstantBuff(getFraseLang("spider bite", -1));
            }  
        } 
        cardDone();    
        break;
    // LANCEKNIGHT
    case ACTIONS.LANDSKN_ATTACK_VERT:
        state = CARD_STATES.PERFORM_ACTION;
        var myind = cardPosToIndex(x, y);
        if (myind >= global.cardsOnBoard / 2)
            myind -= global.cardsOnBoard / 2;
        var lss = gameGetListByTargetGroup(TARGET_GROUPS.ENEMY_CARDS, myind);
        cardAttack(myind, lss, dmg, atkSpd, -1);
        myind += global.cardsOnBoard / 2;
        cardAttack(myind, lss, dmg, atkSpd, -1);
        break;
    // WOODEN GOLEM
    case ACTIONS.WOOD_GOLEM_CARLO:
        cardChangeHp(1);
        cardDone();
        break;
    // not implemented
    default:
        cardDone();
        break;        
}

if (removeStealth)
{
    if (act != ACTIONS.PASS_THE_TURN)
        if (cardHasBuff(BUFFS.INVISIBILITY, id) != -1)
        {
            cardDeleteBuff(BUFFS.INVISIBILITY);
        }
}

/*
    ATTACK = 0,
    PASS_THE_TURN,
    // KOCNHA
    KONCHA_HEAL,
    KONCHA_POISON,
    // LISA
    LISA_ARMOR,
    // MIMIC WILD
    MIMIC_WILD_BATTLECRY,
    MIMIC_WILD_STUN,
    // MIMIC TOWN
    MIMIC_TOWN_BATTLECRY,
    // MUSHROOMS
    MUSHROOMS_POISON,
    MUSHROOMS_ATTACK_DEATH,
    // ARMOR HAMMER
    ARMOR_HAMMER_USE

