///cardDeleteBuff(BUFFS ind)
var b = argument0;
for (var i = 0, c = ds_list_size(buffs); i < c; i++)
{
    var ls = buffs[| i];
    if (ls[| 0] == b)
    {
        switch (b)
        {
        case BUFFS.INVISIBILITY:
            // visible now
            image_alpha = 1;
            break;
        case BUFFS.FIRE_ARROWS:
            cardChangeDmg(-2);
            break;
        case BUFFS.GREAT_HEAL: // heal all by 3
            var pl = player;
            with (oCardBase)
            {
                if (pl == player)
                {
                    cardChangeHp(3);
                }
            }
            break;
        }
        ds_list_destroy(ls);
        ds_list_delete(buffs, i);
        exit; 
    }
}
