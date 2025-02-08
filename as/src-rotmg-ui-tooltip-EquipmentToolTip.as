package rotmg.ui.tooltip
{
   import com.adobe.images.PNGEncoder;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.TimerEvent;
   import flash.filters.DropShadowFilter;
   import flash.geom.Point;
   import flash.net.FileReference;
   import flash.text.StyleSheet;
   import flash.text.TextFieldAutoSize;
   import flash.utils.ByteArray;
   import flash.utils.Dictionary;
   import flash.utils.Timer;
   import rotmg.constants.ActivationType;
   import rotmg.constants.ItemConstants;
   import rotmg.constants.SpecialEffects;
   import rotmg.game.view.components.MaterialSlot;
   import rotmg.misc.UILabel;
   import rotmg.objects.ObjectLibrary;
   import rotmg.objects.Player;
   import rotmg.objects.ProjectileGO;
   import rotmg.objects.itemData.ActivateEffect;
   import rotmg.objects.itemData.CondEffect;
   import rotmg.objects.itemData.CustomToolTipData;
   import rotmg.objects.itemData.ExplodeDesc;
   import rotmg.objects.itemData.ItemAnimationFrame;
   import rotmg.objects.itemData.ItemData;
   import rotmg.objects.itemData.MaskDescription;
   import rotmg.objects.itemData.ProjectileDesc;
   import rotmg.objects.itemData.StatBoost;
   import rotmg.parameters.Parameters;
   import rotmg.ui.SimpleText;
   import rotmg.ui.Stats;
   import rotmg.ui.panels.itemgrids.ContainerGrid;
   import rotmg.ui.panels.itemgrids.ItemGrid;
   import rotmg.ui.reforge.components.ReforgeStats;
   import rotmg.util.AssetLibrary;
   import rotmg.util.BitmapUtil;
   import rotmg.util.FilterUtil;
   import rotmg.util.KeyCodes;
   import rotmg.util.MathUtil2;
   import rotmg.util.MoreColorUtil;
   import rotmg.util.TextureRedrawer;
   import rotmg.util.TierUtil;
   
   public class EquipmentToolTip extends ToolTip
   {
      private static const MAX_WISMOD:int = 1000;
      
      private static const MIN_WISMOD:int = 50;
      
      public static const STAT_VIT:int = 26;
      
      public static const STAT_WIS:int = 27;
      
      public static const STAT_ATK:int = 20;
      
      public static const STAT_DEX:int = 28;
      
      public static const STAT_DEF:int = 21;
      
      public static const STAT_SPD:int = 22;
      
      public static const STAT_HP:int = 0;
      
      public static const STAT_MP:int = 3;
      
      private static const IGNORE_AE:Array = [ActivationType.SHOOT,ActivationType.PET,ActivationType.CREATE,ActivationType.UNLOCK_PORTAL,ActivationType.SHURIKEN_ABILITY,ActivationType.DAZE_BLAST,ActivationType.MASK,ActivationType.DYE,ActivationType.ALLY_TOSS,ActivationType.PORTAL_TRANSFORM,ActivationType.FOUNTAIN_COIN,ActivationType.FLASH,ActivationType.TREASURE_KEY,ActivationType.GHOST_EXTERMINATOR,ActivationType.SHOW_EFFECT];
      
      private static const CSS_TEXT:String = ".aeIn { margin-left:10px; text-indent:-4px; }" + ".ieIn { margin-left:10px; text-indent:-10px; }";
      
      protected static const WIDTH:int = 230;
      
      protected static var HEIGHT:int = 580;
      
      private static const SCROLL_VELOCITY:int = 15;
      
      public var player:Player;
      
      public var equipData:ItemData;
      
      public var itemData:ItemData;
      
      public var icon:Bitmap;
      
      public var descText:SimpleText;
      
      private var usableBy:Boolean;
      
      private var line1:Sprite;
      
      private var line2:Sprite;
      
      private var frames:Vector.<ItemAnimationFrame>;
      
      private var currFrame:int;
      
      private var displayText:SimpleText;
      
      private var specialityText:SimpleText;
      
      private var tierLabel:UILabel;
      
      private var bagIcon:Bitmap;
      
      private var information:String = "";
      
      private var informationText:SimpleText;
      
      private var attributes:String;
      
      private var attributesText:SimpleText;
      
      private var specifications:String;
      
      private var specificationsText:SimpleText;
      
      private var itemEffects:String;
      
      private var itemEffectsText:SimpleText;
      
      private var specialityColor:uint;
      
      private var backColor:uint;
      
      private var outlineColor:uint;
      
      private var toolTipContainer:Sprite;
      
      private var equipContainer:Sprite;
      
      private var floorLine:Sprite;
      
      private var scrollable:Boolean = false;
      
      private var amountScrolled:int = 0;
      
      private var scrollingHelper:Sprite;
      
      private var nullQuestionMarks_:Array;
      
      public function EquipmentToolTip(container:DisplayObject, itemData:ItemData, owner:Player = null)
      {
         var equipId:int = 0;
         this.itemData = itemData;
         if(Boolean(owner))
         {
            this.player = owner;
            equipId = GetEquipIndex(itemData.SlotType,owner.equipment_);
            if(equipId != -1)
            {
               this.equipData = owner.equipment_[equipId];
            }
            this.player.currentEquipToolTip = this;
         }
         this.usableBy = IsUsableBy(owner,itemData.SlotType);
         this.specialityColor = TooltipHelper.getSpecialityColor(this.itemData);
         this.backColor = this.usableBy ? 3552822 : 6036765;
         this.outlineColor = this.usableBy ? 10197915 : 10965039;
         super(container,this.backColor,1,this.outlineColor,1,true,1,WIDTH,HEIGHT,true);
         this.addContainers();
         this.drawIcon();
         this.drawDisplayName();
         this.drawSpeciality();
         this.drawTier();
         this.drawDesc();
         this.drawBagIcon();
         this.makeInformationData();
         this.drawInformationData();
         this.makeAttributes();
         this.drawAttributes();
         this.makeSpecifications();
         this.drawSpecifications();
         this.makeItemEffects();
         this.drawItemEffects();
         if(this.height - 11 > HEIGHT)
         {
            this.scrollable = true;
            this.drawFloorLine();
            this.addMask();
            if(Boolean(Parameters.data.showItemTooltipScroll))
            {
               this.addScrollHelper();
            }
         }
         if(itemData.Null)
         {
            this.descText && (this.descText.x = Math.random() * this.width);
            this.descText && (this.descText.y = Math.random() * this.height);
            this.attributesText && (this.attributesText.x = Math.random() * this.width);
            this.attributesText && (this.attributesText.y = Math.random() * this.height);
            this.specificationsText && (this.specificationsText.x = Math.random() * this.width);
            this.specificationsText && (this.specificationsText.y = Math.random() * this.height);
            this.itemEffectsText && (this.itemEffectsText.x = Math.random() * this.width);
            this.itemEffectsText && (this.itemEffectsText.y = Math.random() * this.height);
            this.informationText && (this.informationText.x = Math.random() * this.width);
            this.informationText && (this.informationText.y = Math.random() * this.height);
            this.icon && (this.icon.x = Math.random() * this.width);
            this.icon && (this.icon.y = Math.random() * this.height);
            this.specialityText && (this.specialityText.x = Math.random() * this.width);
            this.specialityText && (this.specialityText.y = Math.random() * this.height);
            this.displayText && (this.displayText.x = Math.random() * this.width);
            this.displayText && (this.displayText.y = Math.random() * this.height);
            this.tierLabel && (this.tierLabel.x = Math.random() * this.width);
            this.tierLabel && (this.tierLabel.y = Math.random() * this.height);
            this.bagIcon && (this.bagIcon.x = Math.random() * this.width);
            this.bagIcon && (this.bagIcon.y = Math.random() * this.height);
            this.drawNullQuestionMarks();
         }
      }
      
      public static function Round(number:Number, decimalPlaces:int = 1) : Number
      {
         var exp:Number = Math.pow(10,decimalPlaces);
         if(decimalPlaces > 0)
         {
            number = int(number * exp) / exp;
         }
         else if(decimalPlaces == 0)
         {
            number = int(number);
         }
         return number;
      }
      
      private static function GetProjCountText(counts:Vector.<int>) : String
      {
         var count:int = 0;
         var ret:String = "";
         for(var i:int = 0; i < counts.length; i++)
         {
            count = counts[i];
            if(i == counts.length - 1)
            {
               ret += count;
               break;
            }
            ret += count + " => ";
         }
         return ret;
      }
      
      private static function GetProjCountColor(counts:Vector.<int>, counts2:Vector.<int>) : String
      {
         var i:int = 0;
         var sum:int = 0;
         var sum2:int = 0;
         if(counts.length > counts2.length)
         {
            return TooltipHelper.BETTER_COLOR;
         }
         if(counts.length < counts2.length)
         {
            return TooltipHelper.WORSE_COLOR;
         }
         if(counts.length == counts2.length)
         {
            sum = 0;
            for(i = 0; i < counts.length; i++)
            {
               sum += counts[i];
            }
            sum2 = 0;
            for(i = 0; i < counts2.length; i++)
            {
               sum2 += counts2[i];
            }
            return TooltipHelper.getTextColor(sum - sum2);
         }
         return TooltipHelper.NO_DIFF_COLOR;
      }
      
      private static function GetEquipIndex(slotType:int, items:Vector.<ItemData>) : int
      {
         for(var i:int = 0; i < 4; i++)
         {
            if(Boolean(items[i]) && items[i].SlotType == slotType)
            {
               return i;
            }
         }
         return -1;
      }
      
      private static function GetConditionEffectIndex(eff:int, effects:Vector.<CondEffect>) : int
      {
         if(effects == null)
         {
            return -1;
         }
         for(var i:int = 0; i < effects.length; i++)
         {
            if(effects[i].Effect == eff)
            {
               return i;
            }
         }
         return -1;
      }
      
      private static function GetBagTexture(bagType:int, size:int) : BitmapData
      {
         switch(bagType)
         {
            case 0:
               return ObjectLibrary.getRedrawnTextureFromType(1280,size,true);
            case 1:
               return ObjectLibrary.getRedrawnTextureFromType(1286,size,true);
            case 2:
               return ObjectLibrary.getRedrawnTextureFromType(1287,size,true);
            case 3:
               return ObjectLibrary.getRedrawnTextureFromType(1288,size,true);
            case 4:
               return ObjectLibrary.getRedrawnTextureFromType(1289,size,true);
            case 5:
               return ObjectLibrary.getRedrawnTextureFromType(1296,size,true);
            case 6:
               return ObjectLibrary.getRedrawnTextureFromType(1309,size,true);
            case 7:
               return ObjectLibrary.getRedrawnTextureFromType(1305,size,true);
            case 8:
               return ObjectLibrary.getRedrawnTextureFromType(1306,size,true);
            case 9:
               return ObjectLibrary.getRedrawnTextureFromType(1307,size,true);
            case 10:
               return ObjectLibrary.getRedrawnTextureFromType(1304,size,true);
            case 11:
               return ObjectLibrary.getRedrawnTextureFromType(1310,size,true);
            case 12:
               return ObjectLibrary.getRedrawnTextureFromType(1311,size,true);
            case 13:
               return ObjectLibrary.getRedrawnTextureFromType(1312,size,true);
            case 14:
               return ObjectLibrary.getRedrawnTextureFromType(1705,size,true);
            case 15:
               return ObjectLibrary.getRedrawnTextureFromType(1872,size,true);
            case 16:
               return ObjectLibrary.getRedrawnTextureFromType(17056,size,true);
            default:
               return null;
         }
      }
      
      public static function GetEffectColor(effect:int) : String
      {
         switch(effect)
         {
            case SpecialEffects.DRAW_BACK:
               return "#8899FF";
            case SpecialEffects.LIFE_LEECH:
               return "#ED2812";
            case SpecialEffects.MANA_HUNGER:
               return "#227AD8";
            case SpecialEffects.VITAL_POINT:
               return "#8800FF";
            case SpecialEffects.GODS_WISDOM:
               return "#FF99FF";
            case SpecialEffects.ENDURANCE:
               return "#FF6A00";
            case SpecialEffects.GAIA_BLESSING:
               return "#FFD800";
            case SpecialEffects.FIRST_BLOOD:
               return "#880000";
            case SpecialEffects.MIRRORED_SHOT:
               return "#23CDEF";
            case SpecialEffects.DIVINE_POISON:
               return "#FFE95E";
            case SpecialEffects.CURSED_CLOUD:
               return "#D80D0D";
            case SpecialEffects.PURE_HEARTED:
               return "#F6FF00";
            case SpecialEffects.UNBREAKABLE:
               return "#23CDEF";
            case SpecialEffects.CHAOS:
               return "#9634D3";
            case SpecialEffects.NO_MERCY:
               return "#FF3232";
            case SpecialEffects.MIDAS_TOUCH:
               return "#F6FF00";
            case SpecialEffects.ENLIGHTENED:
               return "#F6FF00";
            case SpecialEffects.COLD_HEARTED:
               return "#72BFE0";
            case SpecialEffects.BURNING_MIND:
               return "#FF8300";
            case SpecialEffects.RAMPAGE:
               return "#FF8300";
            case SpecialEffects.PROTECTION_TECHNIQUE:
               return "#B5DAE0";
            case SpecialEffects.EMPOWERED:
               return "#83E02C";
            case SpecialEffects.HOLOGRAM:
               return "#88D5E2";
            case SpecialEffects.CARD_KING:
               return "#E5E5E5";
            case SpecialEffects.UNHOLY_SACRIFICE:
               return "#FF7C72";
            case SpecialEffects.BLOOD_DRAIN:
               return "#C41805";
            case SpecialEffects.LIGHTNING_STRIKE:
               return "#F1FF38";
            case SpecialEffects.BOUND_SOUL:
               return "#80CF5D";
            case SpecialEffects.VORTEX:
               return "#A083EA";
            case SpecialEffects.SOUL_CATALYST:
               return "#3BC8C0";
            case SpecialEffects.MAGIC_BLOOD:
               return "#89091E";
            case SpecialEffects.GREAT_CAT:
               return "#F8D46E";
            case SpecialEffects.SOLAR_ECLIPSE:
               return "#FF8A3D";
            case SpecialEffects.SPACE_EMPEROR:
               return "#20B081";
            case SpecialEffects.KINGS_GUARD:
               return "#FFC84D";
            case SpecialEffects.DEATHS_GRIP:
               return "#CD3333";
            case SpecialEffects.DEATH_MARK:
               return "#D62252";
            case SpecialEffects.HOARDER:
               return "#F9912F";
            case SpecialEffects.SPIDER_BITE:
               return "#5F3097";
            case SpecialEffects.SNOWBALL:
               return "#5685EA";
            case SpecialEffects.DEMON_EYES:
               return "#B21C1C";
            case SpecialEffects.PRIMAL_INSTINCTS:
               return "#A31D45";
            case SpecialEffects.DEATH_CROWS:
               return "#95FA95";
            case SpecialEffects.SOULFLAMES:
               return "#55D471";
            case SpecialEffects.RAGING_INFERNO:
               return "#E8832C";
            case SpecialEffects.ANGER_OF_HADES:
               return "#7A1221";
            case SpecialEffects.SACRIFICE:
               return "#9E192B";
            case SpecialEffects.PUMPKIN:
               return "#FF6B00";
            case SpecialEffects.FLAME_TEMPEST:
               return "#FFCD15";
            case SpecialEffects.UNDEAD_SOULS:
               return "#A5E552";
            case SpecialEffects.POISON_EFFECT1:
               return "#FFFFFF";
            case SpecialEffects.UNDEAD_ARMY:
               return "#6995BF";
            case SpecialEffects.ABRASIVE:
               return "#57AF81";
            case SpecialEffects.STARWEAVER:
               return "#FFCE47";
            case SpecialEffects.GORGONS_GAZE:
               return "#E63377";
            case SpecialEffects.AID_OF_THE_FOREST:
               return "#E18134";
            case SpecialEffects.SCORCHED_EARTH:
               return "#EA5E12";
            case SpecialEffects.IGNITION:
               return "#EA5E12";
            case SpecialEffects.VOID_ARMY:
               return "#24248F";
            case SpecialEffects.ETERNAL_BLESSING:
               return "#4ECC14";
            case SpecialEffects.BLASPHEMY:
               return "#A30B24";
            case SpecialEffects.RUIN:
               return "#A30B24";
            case SpecialEffects.LUNATIC:
               return "#2BADAD";
            case SpecialEffects.OBSESSED_FOLLOWER:
               return "#87091E";
            case SpecialEffects.FLAME_MANTLE:
               return "#EA5E12";
            case SpecialEffects.EXECUTION:
               return "#892355";
            case SpecialEffects.CRIPPLED:
               return "#32BA7C";
            case SpecialEffects.DECAPITATE:
               return "#C4083E";
            case SpecialEffects.FAME_KINGPIN:
               return "#F29000";
            case SpecialEffects.FIGHTER_BUNNY:
               return "#FF70A4";
            case SpecialEffects.EXPLOSIVE_EGGS:
               return "#FFC02D";
            case SpecialEffects.HORSE_STANCE:
               return "#6D353C";
            case SpecialEffects.REWIND:
               return "#1155cc";
            case SpecialEffects.PLOT_ARMOR:
               return "#367579";
            case SpecialEffects.CLOAKED:
               return "#367579";
            case SpecialEffects.BLING:
               return "#7accef";
            case SpecialEffects.ELVISH_MASTERY:
               return "#57d2e0";
            case SpecialEffects.GNOMIFICATION:
               return "#9e2525";
            case SpecialEffects.TRICK_POT:
               return "#3E995E";
            case SpecialEffects.HEAVENS_FEEL:
               return "#6774ff";
            case SpecialEffects.INCINERATION:
               return "#8c1010";
            case SpecialEffects.LUCKY_CHARM:
               return "#38a02c";
            case SpecialEffects.ROLLING_HEADS:
               return "#C4083E";
            case SpecialEffects.BIRDLINGS:
               return "#70482F";
            case SpecialEffects.HAUNTED:
               return "#8AB4D8";
            case SpecialEffects.ENDLESS_FEAST:
               return "#696B36";
            case SpecialEffects.UNDEAD_LEGION:
               return "#6995BF";
            case SpecialEffects.VOID_LEGION:
               return "#24248F";
            case SpecialEffects.AVALANCHE:
               return "#5685EA";
            case SpecialEffects.BIG_PUMPKIN:
               return "#FF6B00";
            case SpecialEffects.LEAF_STORM:
               return "#3F9C4A";
            case SpecialEffects.LEAF_MAELSTROM:
               return "#9AE25A";
            case SpecialEffects.HUNDRED_CUTS:
               return "#CD7A4B";
            case SpecialEffects.THOUSAND_CUTS:
               return "#EBA44E";
            case SpecialEffects.HAMMER_THROW:
               return "#E5A244";
            case SpecialEffects.HAMMER_TIME:
               return "#B57336";
            case SpecialEffects.BROKEN_HEROS_BLADE:
               return "#FFC472";
            case SpecialEffects.HEROS_BLADE:
               return "#E09A31";
            case SpecialEffects.POLAR_RESTORATION:
               return "#9B4AA4";
            case SpecialEffects.POLAR_ENTROPY:
               return "#4C8DB0";
            case SpecialEffects.DISCORD:
               return "#2B9668";
            case SpecialEffects.DISCORDIA:
               return "#B7E55B";
            case SpecialEffects.HYPOTHERMIA:
               return "#5D94CC";
            case SpecialEffects.FROSTBITE:
               return "#A5D6FF";
            case SpecialEffects.RUDE_BUSTER:
               return "#A5214D";
            case SpecialEffects.BIG_SHOT:
               return "#E22255";
            case SpecialEffects.INKPLOSION:
               return "#EA7725";
            case SpecialEffects.FERAL_GAZE:
               return "#FFDE3D";
            case SpecialEffects.MARK_OF_THE_HUNTRESS:
               return "#008FB7";
            case SpecialEffects.MARK_OF_THE_ANCIENTS:
               return "#00E5E5";
            case SpecialEffects.BOUND_SOULS:
               return "#412BAF";
            case SpecialEffects.UNBOUND_SOULS:
               return "#9532FF";
            case SpecialEffects.THRILL_OF_THE_HUNT:
               return "#4B7A3D";
            case SpecialEffects.GOBLIN_MASSACRE:
               return "#8DB259";
            case SpecialEffects.SOLAR_FLARE:
               return "#DB9D00";
            case SpecialEffects.SOLAR_WINDS:
               return "#F3D600";
            case SpecialEffects.WILDFIRE:
               return "#F96A00";
            case SpecialEffects.FIRE_DEVIL:
               return "#F73500";
            case SpecialEffects.SOUL_DRAIN:
               return "#BF2855";
            case SpecialEffects.BLAZE:
               return "#DD2C2C";
            case SpecialEffects.CREMATION:
               return "#F76B25";
            case SpecialEffects.LAMENT:
               return "#659CCC";
            case SpecialEffects.DOWNPOUR:
               return "#81C2D2";
            case SpecialEffects.HOLY_SURGE:
               return "#3BC8C0";
            case SpecialEffects.DOGMA:
               return "#54F0AB";
            case SpecialEffects.OFFERING:
               return "#990019";
            case SpecialEffects.UNHOLY_OFFERING:
               return "#CC0010";
            case SpecialEffects.MANIA:
               return "#E86130";
            case SpecialEffects.MANIC_MENTAL:
               return "#CC3628";
            case SpecialEffects.BULWARK:
               return "#9B1037";
            case SpecialEffects.IMMOVABLE:
               return "#CD3333";
            case SpecialEffects.HUNGRY_SCHOLAR:
               return "#6AC160";
            case SpecialEffects.ALL_CONSUMING_HUNGER:
               return "#A0F364";
            case SpecialEffects.SPLIT_THE_SKIES:
               return "#FF9A0C";
            case SpecialEffects.PIERCE_THE_HEAVENS:
               return "#FFDC1C";
            case SpecialEffects.BALANCE:
               return "#F0B245";
            case SpecialEffects.DUALITY:
               return "#CD3333";
            case SpecialEffects.SWORN_DUTY:
               return "#E2AA38";
            case SpecialEffects.SWORN_DEFENDER:
               return "#FFDF3F";
            case SpecialEffects.SURPRISE:
               return "#D81525";
            case SpecialEffects.BLOODY_SURPRISE:
               return "#F24856";
            case SpecialEffects.ROYAL_MAGIC:
               return "#3488A0";
            case SpecialEffects.ROYAL_FURY:
               return "#54F0AB";
            case SpecialEffects.PITCH_BLACK:
               return "#3F0F99";
            case SpecialEffects.PERFECT_DARK:
               return "#4753D3";
            case SpecialEffects.BAD_PRACTICE:
               return "#58C5FF";
            case SpecialEffects.MEGALOMANIAC:
               return "#83F0FF";
            case SpecialEffects.METEOR_SHOWER:
               return "#E66012";
            case SpecialEffects.DEFENSE_PROTOCOL:
               return "#82BF50";
            case SpecialEffects.DEFENSE_MATRIX:
               return "#C5EF47";
            case SpecialEffects.GIGANTIC:
               return "#F2C43C";
            case SpecialEffects.COLOSSAL:
               return "#FFDF3F";
            case SpecialEffects.BELLS_AND_WHISTLES:
               return "#FFBA4C";
            case SpecialEffects.SHINY_BELLS_AND_WHISTLES:
               return "#FFEF66";
            case SpecialEffects.CHAOS_CHAOS:
               return "#3AAA6A";
            case SpecialEffects.METAMORPHOSIS:
               return "#88DC3C";
            case SpecialEffects.BLOOD_OFFERING:
               return "#7C151E";
            case SpecialEffects.TRANSMUTATION:
               return "#D01E2D";
            case SpecialEffects.RITUALIST:
               return "#CC9528";
            case SpecialEffects.REVENANT:
               return "#E5B42D";
            case SpecialEffects.ACCURSED_BLOOD:
               return "#8E243F";
            case SpecialEffects.MELTING_BLOOD:
               return "#E03940";
            case SpecialEffects.FADING:
               return "#595FA8";
            case SpecialEffects.FORGOTTEN:
               return "#8F78E2";
            case SpecialEffects.EQUILIBRIUM:
               return "#E07FB3";
            case SpecialEffects.OMNISCIENT:
               return "#FFB2CB";
            case SpecialEffects.IMMORTALITY_1:
               return "#58C5FF";
            case SpecialEffects.IMMORTALITY_2:
               return "#83F0FF";
            case SpecialEffects.COSMIC_HERMIT:
               return "#E8551B";
            case SpecialEffects.COSMIC_SAGE:
               return "#FFCB00";
            case SpecialEffects.REINFORCED:
               return "#3B6BAA";
            case SpecialEffects.INDESTRUCTIBLE:
               return "#88C5F7";
            case SpecialEffects.JUGGERNAUT:
               return "#6E6DCB";
            case SpecialEffects.ABLAZE:
               return "#B34520";
            case SpecialEffects.EXACERBATE:
               return "#8E243F";
            case SpecialEffects.OGRISH_REGALIA:
               return "#EBAD10";
            case SpecialEffects.MIGHT_OF_THE_ANCIENTS:
               return "#FFBE63";
            case SpecialEffects.NULLIFY:
               return "#354CB2";
            case SpecialEffects.HIDDEN_TECHNIQUE:
               return "#992432";
            case SpecialEffects.ABSOLUTE_ZERO:
               return "#A5D6FF";
            case SpecialEffects.GLACIAL_TEMPEST:
               return "#5D94CC";
            case SpecialEffects.FEEDING_FRENZY:
               return "#FD7107";
            case SpecialEffects.DESECRATE:
               return "#FF732D";
            case SpecialEffects.FRENZY:
               return "#E5B42D";
            case SpecialEffects.HYPERSPEED:
               return "#FFBB00";
            case SpecialEffects.VOWOFSILENCE:
               return "#81C2D2";
            case SpecialEffects.GROWTHMATTER:
               return "#38A78A";
            case SpecialEffects.FEELINGFINE:
               return "#386EA7";
            case SpecialEffects.GLOOPYTOUCH:
               return "#E9C569";
            case SpecialEffects.OOEYGOOEYINFUSION:
               return "#D85260";
            case SpecialEffects.COSMICCONJURING:
               return "#B09CEE";
            case SpecialEffects.FEEDTHEBEAST:
               return "#38A78A";
            case SpecialEffects.GOOCLONES:
               return "#38A78A";
            case SpecialEffects.MOBIUSEFFECT:
               return "#386EA7";
            case SpecialEffects.TOTALTRANSFORMATION:
               return "#386EA7";
            case SpecialEffects.SLIMELIGHT:
               return "#E9C569";
            case SpecialEffects.FTL:
               return "#E9C569";
            case SpecialEffects.OOMPH:
               return "#D85260";
            case SpecialEffects.BUCKETBRAINED:
               return "#D85260";
            case SpecialEffects.RECONSTITUTION:
               return "#B09CEE";
            case SpecialEffects.PINKIMPACT:
               return "#FFB0F6";
            case SpecialEffects.GHOST:
               return "#4753D3";
            case SpecialEffects.DEPOSIT:
               return "#523A28";
            case SpecialEffects.FORBIDDEN_MAGIC:
               return "#7523AF";
            case SpecialEffects.LIONS_BLOOD:
               return "#9B1037";
            case SpecialEffects.THE_BEST_FRIEND:
               return "#FFD623";
            case SpecialEffects.SWIFT_AS_THE_WIND:
               return "#1B8649";
            case SpecialEffects.SUPERNOVA:
               return "#CE39BD";
            case SpecialEffects.CATACLYSM:
               return "#FFCC00";
            case SpecialEffects.HEAVY_ARTILLERY:
               return "#474370";
            case SpecialEffects.LINGERING_WILL:
               return "#54F0AB";
            case SpecialEffects.APOCALYPSE:
               return "#FFFF3F";
            case SpecialEffects.MAGICAL_POISON:
               return "#64B31B";
            case SpecialEffects.CURSED_BARRAGE:
               return "#FC2860";
            case SpecialEffects.VOID_BARRAGE:
               return "#C34CFF";
            case SpecialEffects.PERSONAL_VESSEL:
               return "#4E5DAA";
            case SpecialEffects.MAGI_GENERATOR:
               return "#855CBC";
            case SpecialEffects.BROAD_GUARD:
               return "#FFD968";
            case SpecialEffects.ECHO:
               return "#659CCC";
            case SpecialEffects.LIGHTNING_ROD:
               return "#89C4FF";
            case SpecialEffects.COLOSSAL_CURRENT:
               return "#89C4FF";
            default:
               return "#FFFFFF";
         }
      }
      
      private static function IsUsableBy(player:Player, slotType:int) : Boolean
      {
         if(!player || !ItemConstants.isEquippable(slotType))
         {
            return true;
         }
         return player.slotTypes_.indexOf(slotType) != -1;
      }
      
      private static function ApplyDemonEyesWisMod(value:Number, player:Player) : Number
      {
         if(!player)
         {
            return value;
         }
         var wisdom:Number = Math.min(player.wisdom_,MAX_WISMOD);
         if(wisdom <= 60)
         {
            return value;
         }
         var cooldownDecrease:Number = Math.floor((wisdom - 60) / 20) * 0.5;
         var newValue:Number = Math.max(2,value - cooldownDecrease) - 0.25;
         return Round(newValue,2);
      }
      
      private static function GetMatches(eff:String, effects:Vector.<ActivateEffect>) : Vector.<ActivateEffect>
      {
         var matches:Vector.<ActivateEffect> = new Vector.<ActivateEffect>();
         for(var i:int = 0; i < effects.length; i++)
         {
            if(effects[i].EffectName == eff)
            {
               matches.push(effects[i]);
            }
         }
         return matches;
      }
      
      private static function GetMatchId(eff:ActivateEffect, effects:Vector.<ActivateEffect>) : int
      {
         var match:ActivateEffect = null;
         var matches:Vector.<ActivateEffect> = GetMatches(eff.EffectName,effects);
         for each(match in matches)
         {
            if(match == eff)
            {
               return matches.indexOf(match);
            }
         }
         return -1;
      }
      
      private static function GetAE(eff:String, matchId:int, effects:Vector.<ActivateEffect>) : ActivateEffect
      {
         if(matchId == -1)
         {
            return null;
         }
         var matches:Vector.<ActivateEffect> = GetMatches(eff,effects);
         if(matches.length < matchId + 1)
         {
            return null;
         }
         return matches[matchId];
      }
      
      private static function HasAEStat(stat:String, effName:String, effects:Vector.<ActivateEffect>) : Boolean
      {
         var ae:ActivateEffect = null;
         if(!effects || effects.length < 1)
         {
            return false;
         }
         for each(ae in effects)
         {
            if(!(!ae.EffectName || ae.EffectName == "" || IGNORE_AE.indexOf(ae.EffectName) != -1 || ae.EffectName != effName))
            {
               if(Stats.fromId(ae.Stats) == stat)
               {
                  return true;
               }
            }
         }
         return false;
      }
      
      private static function GetWisModText(val:Number, wisModVal:Number, color:String) : String
      {
         if(wisModVal == val)
         {
            return TooltipHelper.wrapInFontTag(String(wisModVal),color);
         }
         if(wisModVal > val)
         {
            return TooltipHelper.wrapInFontTag(String(wisModVal),color) + TooltipHelper.wrapInFontTag(" (+" + Round(wisModVal - val,2) + ")",TooltipHelper.WISMOD_COLOR);
         }
         return TooltipHelper.wrapInFontTag(String(wisModVal),color) + TooltipHelper.wrapInFontTag(" (" + Round(wisModVal - val,2) + ")",TooltipHelper.WISMOD_COLOR);
      }
      
      private static function LastElement(elem:*, arr:*) : Boolean
      {
         return arr.indexOf(elem) == arr.length - 1;
      }
      
      private static function GetSign(val:Number) : String
      {
         if(val >= 0)
         {
            return "+";
         }
         return "";
      }
      
      public static function WithSign(val:Number) : String
      {
         if(val >= 0)
         {
            return "+" + val;
         }
         return String(val);
      }
      
      private static function BuildGenericAE(eff:ActivateEffect, wisModded:ModdedEffect, rangeColor:String, durationColor:String, condition:String, conditionColor:String) : String
      {
         var ret:String = "";
         var targetPlayer:Boolean = eff.Target == "player";
         var aimAtCursor:Boolean = eff.Center != "player";
         ret += targetPlayer ? "On Allies: " : "On Enemies: ";
         ret += TooltipHelper.wrapInFontTag(condition,conditionColor) + " within ";
         ret += textColor(wisModded.Range,rangeColor) + wisModded.ModRange + " sqrs";
         if(aimAtCursor)
         {
            ret += " at cursor";
         }
         return ret + (" for " + textColor(wisModded.DurationSec,durationColor) + wisModded.ModDurationSec + " secs");
      }
      
      private static function HasAECondition(condition:String, effName:String, effects:Vector.<ActivateEffect>) : Boolean
      {
         var ae:ActivateEffect = null;
         if(!effects || effects.length < 1)
         {
            return false;
         }
         for each(ae in effects)
         {
            if(!(!ae.EffectName || ae.EffectName == "" || IGNORE_AE.indexOf(ae.EffectName) != -1 || ae.EffectName != effName))
            {
               if(ae.ConditionEffect == condition)
               {
                  return true;
               }
            }
         }
         return false;
      }
      
      public static function fameScaleDamage(fame:int, damage:int) : int
      {
         fame = Math.min(fame,10000000);
         return int(damage + 4 / 3 * Math.pow(fame,1 / 3));
      }
      
      public static function noDiffColor(text:*) : String
      {
         return textColor(String(text),TooltipHelper.NO_DIFF_COLOR);
      }
      
      public static function textColor(text:*, color:String) : String
      {
         return TooltipHelper.wrapInFontTag(String(text),color);
      }
      
      public static function textColor2(text:*, color:int) : String
      {
         return TooltipHelper.wrapInFontTag(String(text),MoreColorUtil.toHtmlString(color));
      }
      
      private static function getColor(value1:Number, value2:Number) : String
      {
         return TooltipHelper.getTextColor(value1 - value2);
      }
      
      private static function getConditionName(eff:String) : String
      {
         switch(eff)
         {
            case "EvenMorePowerfulBleeding":
               return "Bleeding III";
            case "PowerfulBleeding":
               return "Bleeding II";
            case "ArmorBroken":
               return "Armor Broken";
            default:
               return eff;
         }
      }
      
      private static function applyHoarderStats(demonicSacrifices:int, statDict:Dictionary, boostDict:Dictionary = null) : void
      {
         demonicSacrifices = Math.min(1,demonicSacrifices);
         var atkIncrease:int = 5 * demonicSacrifices;
         var dexIncrease:int = 5 * demonicSacrifices;
         var spdIncrease:int = 11 * demonicSacrifices;
         var hoarderColor:String = "#F9912F";
         statDict[20] = (statDict[20] || 0) + atkIncrease;
         statDict[28] = (statDict[28] || 0) + dexIncrease;
         statDict[22] = (statDict[22] || 0) + spdIncrease;
         if(!boostDict)
         {
            return;
         }
         boostDict[20] = (boostDict[20] || "") + textColor(" (+" + atkIncrease + ")",hoarderColor);
         boostDict[28] = (boostDict[28] || "") + textColor(" (+" + dexIncrease + ")",hoarderColor);
         boostDict[22] = (boostDict[22] || "") + textColor(" (+" + spdIncrease + ")",hoarderColor);
      }
      
      private static function CountKeys(dict:Dictionary) : int
      {
         var key:Object = null;
         var count:int = 0;
         for(key in dict)
         {
            count++;
         }
         return count;
      }
      
      private function GetEffectText(effect:int) : String
      {
         switch(effect)
         {
            case SpecialEffects.DRAW_BACK:
               return "<b>Drawback:</b> " + "Grants the affected item +7.5% dodge chance, and dodges inflict the dodged enemy with " + "Armor Broken for 3 seconds.";
            case SpecialEffects.LIFE_LEECH:
               return "<b>Life Steal:</b> " + "Heal a small amount of health (8-16 HP) when hitting an enemy. (0.5 second cooldown)";
            case SpecialEffects.MANA_HUNGER:
               return "<b>Mana Leech:</b> " + "Heal a small amount of mana (4-8 MP) when hitting an enemy. (0.5 second cooldown)";
            case SpecialEffects.VITAL_POINT:
               return "<b>Vital Point:</b> " + "Grants the affected item +10% critical hit chance, critical hits grant " + "+2.5% critical multiplier for 3 seconds (capped at +25%).";
            case SpecialEffects.GODS_WISDOM:
               return "<b>God\'s Wisdom:</b> " + "25% chance of removing all negative effects when using an ability.";
            case SpecialEffects.ENDURANCE:
               return "<b>Endurance:</b> " + "50% chance of healing 100% of your HP when hit while below 20% of your maximum HP, with a 30-second cooldown.";
            case SpecialEffects.GAIA_BLESSING:
               return "<b>Gaia\'s Blessing:</b> " + "10% chance of healing 50% of your HP when using an ability.";
            case SpecialEffects.FIRST_BLOOD:
               return "<b>First Blood:</b> " + "Upon hitting an enemy, 50% chance to deal additional 4000 damage. (5 second cooldown per enemy)";
            case SpecialEffects.MIRRORED_SHOT:
               return "<b>Mirrored Shot:</b> " + "Upon hitting an enemy, shoot out a volley of 3 fast bullets with 10 range. " + "Each bullet deals 750 armor piercing damage and can activate item passives. " + "(1.0 second cooldown)";
            case SpecialEffects.DIVINE_POISON:
               return "<b>Divine Poison:</b> " + "20% chance to poison the enemy on hit, dealing 1000 damage over 4 seconds. (0.25 second cooldown)";
            case SpecialEffects.CURSED_CLOUD:
               return "<b>Cursed Cloud:</b> " + "Enemies have a 33% chance to spawn a red cloud on death. " + "The cloud will follow the nearest enemy and curse everything within 3 squares for 2 seconds. The cloud disappears after 6 seconds.";
            case SpecialEffects.PURE_HEARTED:
               return "<b>Pure Hearted:</b> " + "When at 95% of max HP or higher, you deal 10% more weapon damage.";
            case SpecialEffects.UNBREAKABLE:
               return "<b>Unbreakable:</b> " + "Immunity to Armor Penetration, but -50% overall DEF. Armor Broken still works.";
            case SpecialEffects.CHAOS:
               return "<b>Chaos:</b> " + "When hit by a projectile dealing 100 or more damage, " + "your next 5 attacks will shoot an extra projectile that deals 400 damage and weakens the target for 3 seconds. (8s cooldown)";
            case SpecialEffects.NO_MERCY:
               return "<b>No Mercy:</b> " + "Convert 10% of damage taken into additional attack if you take over 40 damage, capping at +15 ATK, effect lasts for 5 seconds. Ignores damage dealt to shield.";
            case SpecialEffects.MIDAS_TOUCH:
               return "<b>Midas Touch:</b> " + "Enemies within 2.5 tile radius are inflicted with Midas Touch effect for 6 seconds. " + "The effect makes you and other people with this item effect deal 20% more damage.";
            case SpecialEffects.ENLIGHTENED:
               return "<b>Enlightened:</b> " + "You and your allies within a 4-square radius receive Healing effect for 5 seconds every 10 seconds.";
            case SpecialEffects.COLD_HEARTED:
               return "<b>Cold Hearted:</b> " + "Every 8 seconds, you will shoot 3 bursts of icicles at the nearest enemy which paralyze them for 3 seconds. " + "All damage you take before this effect procs will be added to the icicle damage.";
            case SpecialEffects.BURNING_MIND:
               return "<b>Burning Mind:</b> " + "Killing enemies gives you +5 ATT and +5 SPD for 4 seconds, capping at +25 ATT and +25 SPD.";
            case SpecialEffects.RAMPAGE:
               return "<b>Rampage:</b> " + "When taking over 40 damage, creates an AoE explosion with a 4-tile radius that deals 400 damage to enemies and Curses them for 3 seconds.";
            case SpecialEffects.PROTECTION_TECHNIQUE:
               return "<b>Protection Technique:</b> " + "Grants the affected item +10% dodge chance, and dodges grant Healing for 2.5 seconds.";
            case SpecialEffects.EMPOWERED:
               return "<b>Empowered:</b> " + "Gives a medium boost to your lowest stat. (+100 to HP/MP, +10 to other stats)";
            case SpecialEffects.HOLOGRAM:
               return "<b>Hologram:</b> " + "On ability use, there is a 40% chance to create a decoy for 6 seconds that will orbit you with a 1.5-tile radius." + " It will shoot at enemies, dealing 200 damage, and slowing them for 4 seconds.";
            case SpecialEffects.CARD_KING:
               return "<b>Card King:</b> " + "When using an ability, there is a 50% chance to spawn one of the 4 cards for 5 seconds: " + "Diamonds - Damaging effect within a 5-sqr radius. " + "Clubs - Weak effect within a 4-sqr radius on enemies. " + "Hearts - Healing effect within a 5-sqr radius. Spades - " + "Curse effect within a 4-sqr radius on enemies.";
            case SpecialEffects.UNHOLY_SACRIFICE:
               return "<b>Unholy Sacrifice:</b> " + "Using your ability also drains 150 HP, and gives you Berserk and Damaging effects for 4 seconds.";
            case SpecialEffects.BLOOD_DRAIN:
               return "<b>Blood Drain:</b> " + "3.5% chance to heal 50 HP when hitting an enemy. (0.5s cooldown)";
            case SpecialEffects.LIGHTNING_STRIKE:
               return "<b>Lightning Strike:</b> " + "20% chance to perform an AoE attack when hitting an enemy.";
            case SpecialEffects.BOUND_SOUL:
               return "<b>Bound Soul:</b> " + "Spawns an ally that follows you and shoots at nearby enemies, dealing 500 damage every 0.3 secs. Every 1.5 secs, it casts a spell bomb at the nearest enemy dealing 2400 damage.";
            case SpecialEffects.VORTEX:
               return "<b>Vortex:</b> " + "Every 8th shot shoots an extra projectile that explodes into 8 projectiles.";
            case SpecialEffects.SOUL_CATALYST:
               return "<b>Soul Catalyst:</b> " + "While equipped, you cycle between 5 different souls followers in a set order every 8 seconds. " + "Each soul gives their own benefit and cycle in this order:\n" + "Red: +20% Critical Hit Chance, Curse all enemies in 6 squares after Red ends\n" + "Blue: +20% Damage Reduction, recover 25% Maximum HP after Blue ends\n" + "Green: +20% Dodge Chance, Slow all enemies in 6 squares after Green ends\n" + "Yellow: +20% MP Cost Reduction, recover 40% Maximum MP after Yellow ends\n" + "Purple: +10% Critical Hit Chance, +10% Damage Reduction, +10% Dodge Chance, +10% MP Cost Reduction\n";
            case SpecialEffects.MAGIC_BLOOD:
               return "<b>Magic Blood:</b> " + "Taking damage regenerates your mana.";
            case SpecialEffects.GREAT_CAT:
               return "<b>Great Cat:</b> " + "Spawns an ally that follows you and helps you in battle.";
            case SpecialEffects.SOLAR_ECLIPSE:
               return "<b>Solar Eclipse:</b> " + "On ability cast, spawn a stationary sun at cursor that stays for 2 seconds " + "and does 1000 armor piercing damage within 4.5 squares every second.";
            case SpecialEffects.SPACE_EMPEROR:
               return "<b>Space Emperor:</b> " + "Gives you immunity to armor penetration. Armor Broken still works.";
            case SpecialEffects.KINGS_GUARD:
               return "<b>King\'s Guard:</b> " + "Gives you immunity to armor penetration. Reduces your defense by 40%. Armor Broken still works.";
            case SpecialEffects.DEATHS_GRIP:
               return "<b>Death\'s Grip:</b> " + "For every 40 souls harvested, you gain a 6% damage boost but lose 4% damage reduction (up to 30% damage boost and -20% damage reduction).";
            case SpecialEffects.DEATH_MARK:
               return "<b>Death Mark:</b> " + "When you poison an enemy, they will be marked. Upon their death, they will arise once more " + "as an undead minion to serve you. " + "Additionally, you spawn one minion every ability use. You can have up to 6 minions alive at once.";
            case SpecialEffects.HOARDER:
               return ("<b>Hoarder:</b> " + "You can sacrifice both Legendary and Demonic items into this armor at the forge.\n" + "Legendary limit: {0}/10\n" + "Each Legendary sacrificed gives: +1% Loot Boost\n" + "Demonic limit: {1}/1\n" + "Each Demonic sacrificed gives: +5% Loot Boost, +5 Attack, +5 Dexterity, +11 Speed").replace("{0}",this.itemData.LegendarySacrifices).replace("{1}",this.itemData.DemonicSacrifices);
            case SpecialEffects.SPIDER_BITE:
               return "<b>Spider Bite:</b> " + "During rage, hitting an enemy poisons them, dealing 1600 damage over 4 seconds. (1.5s cooldown per enemy)";
            case SpecialEffects.SNOWBALL:
               return "<b>Snowball:</b> " + "On ability use, spawn a big snowball that explodes at cursor. (2s cooldown)";
            case SpecialEffects.DEMON_EYES:
               return "<b>Demon Eyes:</b> " + "On ability use, spawn 5 minions that will dash at the nearest enemy and explode, " + "dealing 3000 damage within 2 sqrs. (5s cooldown)";
            case SpecialEffects.PRIMAL_INSTINCTS:
               return "<b>Primal Instincts:</b> " + "While equipped, you become Feral, gaining 20% damage reduction and " + "immunity to Blind, Unstable, Dazed and Weak.";
            case SpecialEffects.DEATH_CROWS:
               return "<b>Death\'s Crows:</b> " + "Spawns 2 crows that fly around you and shoot projectiles along with you dealing 500 damage. " + "The crows are Invulnerable and cannot be killed, but they can block shots for you.";
            case SpecialEffects.SOULFLAMES:
               return "<b>Soulflames:</b> " + "Every 0.75s your braziers have a chance to spawn a soulflame. " + "The soulflames orbit the brazier, and will charge at the nearest enemy within 5 sqrs, " + "dealing 1000 damage within 3 squares.";
            case SpecialEffects.RAGING_INFERNO:
               return "<b>Raging Inferno:</b> " + "Hitting enemies 50 times spawns an intangible inferno vortex on you that lasts for 4 seconds. " + "Every 0.6 seconds, it deals 1200 damage within 6 squares and tosses a flame anywhere within 4 squares. " + "These flames have 100 HP and cast a scepter blast at 5 targets towards cursor for 1000 damage on death. " + "(4 second cooldown)";
            case SpecialEffects.ANGER_OF_HADES:
               return "<b>Anger of Hades:</b> " + "After rage ends, 75% of the damage dealt to enemies during rage will be dealt to them once again.";
            case SpecialEffects.SACRIFICE:
               return "<b>Sacrifice:</b> " + "Upon use, <b>kills</b> your character.";
            case SpecialEffects.PUMPKIN:
               return "<b>Pumpkin:</b> " + "On ability use, spawn a rolling pumpkin that explodes at cursor. (2s cooldown)";
            case SpecialEffects.FLAME_TEMPEST:
               return "<b>Flame Tempest:</b> " + "Every 8th shot shoots an extra projectile that explodes into 8 projectiles.";
            case SpecialEffects.UNDEAD_SOULS:
               return "<b>Undead Souls:</b> " + "Spawn a minion for 6 seconds on ability use. " + "The minion will shoot at nearest enemy every 0.3 seconds, regenerating 5 MP when hitting the target and dealing 100 damage. " + "(Max 4 minions)";
            case SpecialEffects.POISON_EFFECT1:
               return "";
            case SpecialEffects.UNDEAD_ARMY:
               return "<b>Undead Army:</b> " + "After an ability use, if your MP is below 100, spawn an additional zombie. Getting debuffed spawns 2 zombies around you.";
            case SpecialEffects.ABRASIVE:
               return "<b>Abrasive:</b> " + "Every 1.5 seconds, gain 5% dodge chance, stacking up to 25%. " + "Every successful dodge reduces this dodge chance by 10%. " + "Your dodge chance cannot go negative from this effect.";
            case SpecialEffects.STARWEAVER:
               return "<b>Starweaver:</b> " + "On ability use, the first 5 targeted enemies are each surrounded with a circle of 3 stars " + "that converge after half a second and deal 500 damage each. ";
            case SpecialEffects.GORGONS_GAZE:
               return "<b>Gorgon’s Gaze:</b> " + "Every second ability cast throws an additional poison bomb that deals 3000 damage within 5 squares over 3 seconds.";
            case SpecialEffects.AID_OF_THE_FOREST:
               return "<b>Aid of the Forest:</b> " + "All forms of instant healing are increased by 50% when below 30% HP.";
            case SpecialEffects.SCORCHED_EARTH:
               return "<b>Scorched Earth:</b> " + "On hit, applies 0.2 seconds of Scorched. " + "Additional hits of the staff increase the duration of Scorched up to a maximum of 6 seconds, " + "and damage dealt by Scorched scales with the max duration. " + "If the Scorched duration is maxed out, additional shots will fill a secondary bar that, " + "once filled, inflicts a 1500 damage AoE that applies Armor Broken.";
            case SpecialEffects.IGNITION:
               return "<b>Ignition:</b> " + "While ability held, drain health in exchange for bonus damage. " + "Each second held grants 1500 bonus damage per shot. Releasing a fully charged cast " + "grants Berserk and Damaging for 4 secs and " + "applies Scorched to all enemies within 6 squares, dealing 7500 damage over 2 seconds.";
            case SpecialEffects.VOID_ARMY:
               return "<b>Void Army:</b> " + "After an ability use, if your MP is below 100, spawn an additional dragon. Getting debuffed spawns 2 dragons around you.";
            case SpecialEffects.ETERNAL_BLESSING:
               return "<b>Eternal Blessing:</b> " + "Heal 20 health each time a vine deals damage to an enemy. " + "Every third cast spawns five vines around yourself.";
            case SpecialEffects.BLASPHEMY:
               return "<b>Blasphemy:</b> " + "Every second, spawn a lost soul that follows you, up to a maximum of 5. " + "Striking an enemy three times in a row will cause all of your lost souls to charge at them, " + "detonating for 1500 damage within 3 squares. ";
            case SpecialEffects.RUIN:
               return "<b>Ruin:</b> " + "Every second, gain a stack of Madness, up to a maximum of 10. " + "Each stack of Madness grants: 1% damage increase, 2% damage reduction, and 3% magic regeneration. " + "Every hit you take reduces your Madness stacks by 3. " + "Immunity to King’s Madness while equipped.";
            case SpecialEffects.LUNATIC:
               return "<b>Lunatic:</b> " + "On enemy hit, gain a stack of Lunacy, which grants +3 Wisdom and +1 Dexterity. " + "You can only have a maximum of 20 stacks of Lunacy at any time. " + "All Lunacy stacks are consumed upon using an ability.";
            case SpecialEffects.OBSESSED_FOLLOWER:
               return "<b>Obsessed Follower:</b> " + "Spawns an eyeball that follows you, dealing 750 damage " + "(+15 damage per point of Wisdom above 95) to the nearest enemy within 8 tiles every second. " + "Casting your ability will enrage your minion, doubling its attack rate for the next 5 seconds.";
            case SpecialEffects.FLAME_MANTLE:
               return "<b>Flame Mantle:</b> " + "Getting within 5 squares of an enemy while invisible causes them to spontaneously combust, " + "dealing 1000 damage and applying Cursed and Slowed for 4.5 seconds. " + "Enemies hit by this effect cannot be combusted again for 0.5 seconds.";
            case SpecialEffects.EXECUTION:
               return "<b>Execution:</b> " + "Critical Strikes deal an additional 0.5% damage to enemies per 1% of missing health.";
            case SpecialEffects.CRIPPLED:
               return "<b>Crippled:</b> " + "Poisoned enemies take 10% more damage from your weapon and deal 10% less damage to you. " + "This only affects you or other players using this poison.";
            case SpecialEffects.DECAPITATE:
               return "<b>Decapitate:</b> " + "Every enemy kill or 20000 damage dealt to bosses grants you a “head” stack, " + "up to a maximum of 10 stacks. Each head collected grants you 2.5% critical hit chance, " + "up to a maximum of 25%.";
            case SpecialEffects.FAME_KINGPIN:
               return "<b>Fame Kingpin:</b> " + "The damage of this weapon scales with your current account fame, " + "however, you lose 33% of your current fame on death. " + "Damage caps at 10 million Fame and Fame lost caps at 3.3 million.";
            case SpecialEffects.FIGHTER_BUNNY:
               return "<b>Fighter Bunny:</b> " + "Spawns a fighting ally who follows you and fights by your side.";
            case SpecialEffects.EXPLOSIVE_EGGS:
               return "<b>Explosive Eggs:</b> " + "Every 5 seconds throw a big egg at cursor that deals 2500 damage. " + "Also throw an egg every ability use, dealing 1000 damage.";
            case SpecialEffects.HORSE_STANCE:
               return "<b>Horse Stance:</b> " + "On ability cast, gain Berserk and Damaging for 4 seconds, but lose 10 Defense. " + "15 second cooldown.";
            case SpecialEffects.REWIND:
               return "<b>Rewind:</b> " + "On use, start a timer that lasts for 5 seconds. " + "After 5 seconds, reset mana to the amount it was at when the watch was used.";
            case SpecialEffects.PLOT_ARMOR:
               return "<b>Plot Armor:</b> " + "As if the rules of this world change for your own benefit, " + "you have a 25% chance to survive any lethal damage. (20s cooldown)";
            case SpecialEffects.CLOAKED:
               return "<b>Cloaked:</b> " + "For every second you are invisible, you gain +2 DEX, to a maximum of +30 DEX. " + "The boost resets after uncloaking.";
            case SpecialEffects.BLING:
               return "<b>Bling:</b> " + "You shine like a diamond.";
            case SpecialEffects.ELVISH_MASTERY:
               return "<b>Elvish Mastery:</b> " + "Grants your ability a percentage damage increase: Tiered/UT: +50%, LG/DC: +25%";
            case SpecialEffects.GNOMIFICATION:
               return "<b>Gnomification:</b> " + "You see gnomes everywhere and for every player within 7 sqrs you gain +1 Wisdom.";
            case SpecialEffects.TRICK_POT:
               return "<b>Trick Pot:</b> " + "Players hit by this poison regenerate 120 HP over the next 6 seconds.";
            case SpecialEffects.HEAVENS_FEEL:
               return "<b>Heaven\'s Feel:</b> " + "50% of the damage dodged is returned as self healing. (3 sec cooldown)";
            case SpecialEffects.INCINERATION:
               return "<b>Incineration:</b> " + "Your projectiles now bleed enemies for 750 damage per second over 2 seconds. " + "The damage of bleed is increased by 500 for every 35 WIS.";
            case SpecialEffects.LUCKY_CHARM:
               return "<b>Lucky Charm:</b> " + "You gain +10% Loot Boost when equipped.";
            case SpecialEffects.ROLLING_HEADS:
               return "<b>Rolling Heads:</b> " + "Every enemy kill or 16666 damage dealt to bosses grants you a “head” stack, " + "up to a maximum of 12 stacks. Each head collected grants you 2.5% critical hit chance, " + "up to a maximum of 30%. Excess heads gained after cap empower 3 of your next attacks, " + "guaranteeing critical hits.";
            case SpecialEffects.BIRDLINGS:
               return "<b>Birdlings:</b> " + "Your decoys are replaced with birds. " + "The birds deal 400 damage every 0.3 seconds within 3 squares as they travel.";
            case SpecialEffects.HAUNTED:
               return "<b>Haunted:</b> " + "During rage, any enemy you deal damage to is Cursed until your rage wears off.";
            case SpecialEffects.ENDLESS_FEAST:
               return "<b>Endless Feast:</b> " + "During rage, 1.5% of damage dealt is returned to you as healing. " + "Enemies that die within 6 tiles of you are devoured, granting you an additional 1 second of rage.";
            case SpecialEffects.UNDEAD_LEGION:
               return "<b>Undead Legion:</b> " + "After an ability use, if your MP is below 150, spawn an additional zombie. " + "Getting debuffed spawns 3 zombies around you. " + "Berserk and Damaging buffs applied to you are also applied to your zombies.";
            case SpecialEffects.VOID_LEGION:
               return "<b>Void Legion:</b> " + "After an ability use, if your MP is below 150, spawn an additional dragon. " + "Getting debuffed spawns 3 dragons around you. " + "Berserk and Damaging buffs applied to you are also applied to your dragons.";
            case SpecialEffects.AVALANCHE:
               return "<b>Avalanche:</b> " + "On ability use, spawn a huge snowball that explodes at cursor " + "and launches four snowball grenades into the air, dealing 500 damage each " + "within 2.5 squares upon landing. (2s cooldown)";
            case SpecialEffects.BIG_PUMPKIN:
               return "<b>Big Pumpkin:</b> " + "On ability use, spawn a big pumpkin that explodes at cursor " + "and launches four grenades into the air, dealing 500 damage each " + "within 2.5 squares upon landing. (2s cooldown)";
            case SpecialEffects.LEAF_STORM:
               return "<b>Leaf Storm:</b> " + "While shooting, every second, emit 3 swirling leaf projectiles that deal 500 armor piercing damage " + "and bleed enemies for 1250 damage over 2.5 seconds. " + "Projectiles will shoot at your cursor at the end of their lifetime.";
            case SpecialEffects.LEAF_MAELSTROM:
               return "<b>Leaf Maelstrom:</b> " + "While shooting, every second, emit 3 swirling leaf projectiles that deal 750 armor piercing damage " + "and bleed enemies for 2500 damage over 2.5 seconds. " + "Projectiles will shoot at your cursor at the end of their lifetime.";
            case SpecialEffects.HUNDRED_CUTS:
               return "<b>Hundred Cuts:</b> " + "On enemy hit, 20% chance to unleash a flurry of six slashes that deal 300 armor piercing damage. (1.5 second cooldown)";
            case SpecialEffects.THOUSAND_CUTS:
               return "<b>Thousand Cuts:</b> " + "On enemy hit, 20% chance to unleash a flurry of eight slashes that deal 300 armor piercing damage. (1.0 second cooldown)";
            case SpecialEffects.HAMMER_THROW:
               return "<b>Hammer Throw:</b> " + "On shoot, throws a hammer at cursor that deals 3000 damage within 5.5 squares and " + "inflicts Armor Broken for 3 seconds. (4s cooldown)";
            case SpecialEffects.HAMMER_TIME:
               return "<b>Hammer Time:</b> " + "On shoot, throws a hammer at cursor that deals 3000 damage within 7 squares and " + "inflicts Armor Broken for 3 seconds. (3s cooldown)";
            case SpecialEffects.BROKEN_HEROS_BLADE:
               return "<b>Broken Hero\'s Blade:</b> " + "While above 95% Max HP, you deal 10% more weapon damage.";
            case SpecialEffects.HEROS_BLADE:
               return "<b>Hero\'s Blade:</b> " + "While above 85% Max HP, you deal 15% more weapon damage.";
            case SpecialEffects.POLAR_RESTORATION:
               return "<b>Polar Restoration:</b> " + "On enemy hit, 6% chance to regenerate 15 MP and gain +10 WIS for 3 seconds. (1s cooldown)";
            case SpecialEffects.POLAR_ENTROPY:
               return "<b>Polar Entropy:</b> " + "On enemy hit, 6% chance to regenerate 20 MP, and gain +12 Wisdom for 3 seconds. (1s cooldown)";
            case SpecialEffects.DISCORD:
               return "<b>Discord:</b> " + "On enemy hit, spawns a Chaos Flame on them for 5 seconds. " + "Chaos Flame functions like a decoy, and has 2000 HP. " + "On death, the flame explodes, dealing 6000 damage within 3 squares. (8.5s cooldown)";
            case SpecialEffects.DISCORDIA:
               return "<b>Discordia:</b> " + "On enemy hit, spawns a Chaos Flame on them for 6 seconds. " + "Chaos Flame functions like a decoy, and has 2500 HP. " + "On death, the flame explodes, dealing 7500 damage within 3 squares. (8.5s cooldown)";
            case SpecialEffects.HYPOTHERMIA:
               return "<b>Hypothermia:</b> " + "Striking an enemy 25 times causes them to explode, " + "shooting out 4 piercing ice shards that deal 300 armor piercing damage and Slow for 3 seconds.";
            case SpecialEffects.FROSTBITE:
               return "<b>Frostbite:</b> " + "Striking an enemy 25 times causes them to explode, " + "shooting out 4 piercing ice shards that deal 400 armor piercing damage and Slow for 5 seconds.";
            case SpecialEffects.RUDE_BUSTER:
               return "<b>Rude Buster:</b> " + "Every 10th shot fired is a guaranteed critical hit.";
            case SpecialEffects.BIG_SHOT:
               return "<b>Big Shot:</b> " + "Every 8th shot fired is a guaranteed critical hit.";
            case SpecialEffects.INKPLOSION:
               return "<b>Inksplosion:</b> " + "On enemy hit, 3% chance to spawn an ink beholder that charges the nearest enemy, " + "dealing 1500 damage within 3 squares.";
            case SpecialEffects.FERAL_GAZE:
               return "<b>Feral Gaze:</b> " + "On enemy hit, 5% chance to spawn an ink beholder that charges the nearest enemy, " + "dealing 1500 damage within 5 squares.";
            case SpecialEffects.MARK_OF_THE_HUNTRESS:
               return "<b>Mark of the Huntress:</b> " + "On enemy hit, 10% chance to activate your currently equipped ability for free. " + "Cooldown scales with MP Cost. " + "(" + this.getMarkOfTheHuntressCooldown() + "s cooldown)";
            case SpecialEffects.MARK_OF_THE_ANCIENTS:
               return "<b>Mark of the Ancients:</b> " + "On enemy hit, 20% chance to activate your currently equipped ability for free. " + "Cooldown scales with MP Cost. " + "(" + this.getMarkOfTheHuntressCooldown() + "s cooldown)";
            case SpecialEffects.BOUND_SOULS:
               return "<b>Bound Souls:</b> " + "Each shot landed on an enemy grants you a stack of Void, up to a max of 50 stacks. " + "Every 3 stacks of Void grants you +1% attack speed. " + "Upon reaching 50 stacks of Void, you lose all of your Void stacks and are healed for 50 HP.";
            case SpecialEffects.UNBOUND_SOULS:
               return "<b>Unbound Souls:</b> " + "Each shot landed on an enemy grants you a stack of Void, up to a max of 40 stacks. " + "Every 2 stacks of Void grants you +1% attack speed. " + "Upon reaching 40 stacks of Void, you lose all of your Void stacks and are healed for 60 HP.";
            case SpecialEffects.THRILL_OF_THE_HUNT:
               return "<b>Thrill of the Hunt:</b> " + "While equipped, gain Armored while within 5 squares of an enemy.";
            case SpecialEffects.GOBLIN_MASSACRE:
               return "<b>Goblin Massacre:</b> " + "While equipped, gain Armored and 10% Damage reduction while within 5 squares of an enemy.";
            case SpecialEffects.SOLAR_FLARE:
               return "<b>Solar Flare:</b> " + "On enemy hit, 10% chance to channel a scepter blast, dealing 600 damage on up to 5 targets.";
            case SpecialEffects.SOLAR_WINDS:
               return "<b>Solar Winds:</b> " + "On enemy hit, 10% chance to channel a scepter blast, dealing 1200 damage on up to 5 targets.";
            case SpecialEffects.WILDFIRE:
               return "<b>Wildfire:</b> " + "On enemy hit, 4% chance to spawn a flaming tornado for 3 seconds that chases the nearest enemy, " + "shooting shots that deal 150 armor piercing damage every 0.7 seconds.";
            case SpecialEffects.FIRE_DEVIL:
               return "<b>Fire Devil:</b> " + "On enemy hit, 4% chance to spawn a flaming tornado for 3 seconds that chases the nearest enemy, " + "shooting shots that deal 250 armor piercing damage every 0.7 seconds.";
            case SpecialEffects.SOUL_DRAIN:
               return "<b>Soul Drain:</b> " + "5% chance to heal 50 HP and 30 MP when hitting an enemy. (0.5s cooldown)";
            case SpecialEffects.BLAZE:
               return "<b>Blaze:</b> " + "Every 15 critical hits fires a meteor at the enemy closest to cursor, " + "dealing 1200 damage on impact and dealing 1800 damage over 3 seconds within 4 squares.";
            case SpecialEffects.CREMATION:
               return "<b>Cremation:</b> " + "Every 15 critical hits fires a meteor at the enemy closest to cursor, " + "dealing 1600 damage on impact and dealing 2400 damage over 3 seconds within 6 squares.";
            case SpecialEffects.LAMENT:
               return "<b>Lament:</b> " + "On ability cast, spawn a stationary rain spirit on self that shoots towards your cursor, " + "firing armor piercing shots every 0.2 seconds that deal 50% of your current damage. " + "Casting your ability again despawns the current rain spirit and replaces it with a new one.";
            case SpecialEffects.DOWNPOUR:
               return "<b>Downpour:</b> " + "On ability cast, spawn a stationary rain spirit on self that shoots towards your cursor, " + "firing armor piercing shots every 0.2 seconds that deal 75% of your current damage. " + "Casting your ability again despawns the current rain spirit and replaces it with a new one.";
            case SpecialEffects.HOLY_SURGE:
               return "<b>Holy Surge:</b> " + "Every 6 seconds, transform into a holy wraith for 3 seconds, " + "reducing your mana cost by 10% and increasing all damage dealt by 10%.";
            case SpecialEffects.DOGMA:
               return "<b>Dogma:</b> " + "Every 6 seconds, transform into a holy wraith for 3 seconds, " + "reducing your mana cost by 15% and increasing all damage dealt by 12%.";
            case SpecialEffects.OFFERING:
               return "<b>Offering:</b> " + "Killing an enemy grants +20 HP and +20 MP. (0.5s cooldown)";
            case SpecialEffects.UNHOLY_OFFERING:
               return "<b>Unholy Offering:</b> " + "Killing an enemy grants +20 HP and +20 MP. " + "On enemy hit, 5% chance to regenerate +20 HP and +20 MP. (0.5s cooldown)";
            case SpecialEffects.MANIA:
               return "<b>Mania:</b> " + "While buffed with Berserk, gain +6 Dexterity, and while buffed with Damaging, gain +6 Attack.";
            case SpecialEffects.MANIC_MENTAL:
               return "<b>Manic Mental:</b> " + "While buffed with Berserk, gain +8 Dexterity, and while buffed with Damaging, gain +8 Attack. " + "Being buffed with either Damaging or Berserk will automatically grant you the other.";
            case SpecialEffects.BULWARK:
               return "<b>Bulwark:</b> " + "While above 90% Maximum HP, gain immunity to all negative conditions.";
            case SpecialEffects.IMMOVABLE:
               return "<b>Immovable:</b> " + "While above 80% Maximum HP, gain immunity to all negative conditions.";
            case SpecialEffects.HUNGRY_SCHOLAR:
               return "<b>Hungry Scholar:</b> " + "After hitting 45 shots, your next ability cast costs 50% less mana.";
            case SpecialEffects.ALL_CONSUMING_HUNGER:
               return "<b>All-Consuming Hunger:</b> " + "After hitting 45 shots, your next ability cast costs 75% less mana.";
            case SpecialEffects.SPLIT_THE_SKIES:
               return "<b>Split the Skies:</b> " + "On enemy hit, 7.5% chance to deal 700 damage within 5 squares.";
            case SpecialEffects.PIERCE_THE_HEAVENS:
               return "<b>Pierce the Heavens:</b> " + "On enemy hit, 7.5% chance to deal 1000 damage within 6 squares.";
            case SpecialEffects.BALANCE:
               return "<b>Balance:</b> " + "On ability cast, alternate between an Offensive and Defensive mode. " + "Offensive mode grants +7.5% attack speed, and Defense mode grants +7.5% damage reduction.";
            case SpecialEffects.DUALITY:
               return "<b>Duality:</b> " + "On ability cast, alternate between an Offensive and Defensive mode. " + "Offensive mode grants +10% attack speed, and Defense mode grants +10% damage reduction.";
            case SpecialEffects.SWORN_DUTY:
               return "<b>Sworn Duty:</b> " + "While your Eye of Marble is active, taking damage causes your " + "Eye of Marble to heal 30 HP within 6 squares. (0.5s cooldown)";
            case SpecialEffects.SWORN_DEFENDER:
               return "<b>Sworn Defender:</b> " + "While your Eye of Marble is active, taking damage causes your " + "Eye of Marble to heal 50 HP within 6 squares. (0.5s cooldown)";
            case SpecialEffects.SURPRISE:
               return "<b>Surprise:</b> " + "While cloaked, 15% of your damage dealt is stored. " + "Your next ability cast with this cloak releases the stored damage, " + "damaging all enemies within 4 squares.";
            case SpecialEffects.BLOODY_SURPRISE:
               return "<b>Bloody Surprise:</b> " + "While cloaked, 20% of your damage dealt is stored. " + "Your next ability cast with this cloak releases the stored damage, " + "damaging all enemies within 5 squares.";
            case SpecialEffects.ROYAL_MAGIC:
               return "<b>Royal Magic:</b> " + "Every quiver shot landed grants a stacking Damaging for 1.5 seconds, up to a maximum " + "duration of 4.5 seconds.";
            case SpecialEffects.ROYAL_FURY:
               return "<b>Royal Fury:</b> " + "Every quiver shot landed grants a stacking Damaging for 1.5 seconds, up to a maximum " + "duration of 4.5 seconds. If paired with King\'s Crossbow, gain an additional set of shots on " + "your barrage";
            case SpecialEffects.PITCH_BLACK:
               return "<b>Pitch Black:</b> " + "Hitting an enemy with your ability causes them to take 10% more damage from you for 3 seconds.";
            case SpecialEffects.PERFECT_DARK:
               return "<b>Perfect Dark:</b> " + "Hitting an enemy with your ability causes them to take 15% more damage from you for 3 seconds.";
            case SpecialEffects.BAD_PRACTICE:
               return "<b>Bad Practice:</b> " + "On ability cast, deal damage to all enemies within 10 squares equal to 1.5x the health you restore to allies and yourself. " + "Capped at 7500 damage per cast.";
            case SpecialEffects.MEGALOMANIAC:
               return "<b>Megalomaniac:</b> " + "On ability cast, deal damage to all enemies within 10 squares equal to 2x the health you restore to allies and yourself. " + "Capped at 7500 damage per cast.";
            case SpecialEffects.METEOR_SHOWER:
               return "<b>Meteor Shower:</b> " + "On ability use, the first 5 targeted enemies are each surrounded with a circle of 3 stars " + "that converge immediately and deal 750 damage each.";
            case SpecialEffects.DEFENSE_PROTOCOL:
               return "<b>Defense Protocol:</b> " + "Shield Recharge Time is reduced by 15%. While you have any shield, gain +10 ATK and +20 SPD.";
            case SpecialEffects.DEFENSE_MATRIX:
               return "<b>Defense Matrix:</b> " + "Shield Recharge Time is reduced by 25%. While you have any shield, gain +15 ATK and +20 SPD.";
            case SpecialEffects.GIGANTIC:
               return "<b>Gigantic:</b> " + "On enemy hit, deal 2000 damage (+1 damage for each point of HP), " + "and heal back 5% of the damage dealt. (8s cooldown)";
            case SpecialEffects.COLOSSAL:
               return "<b>Colossal:</b> " + "On enemy hit, deal 2500 damage (+1 damage for each point of HP), " + "and heal back 5% of the damage dealt. (8s cooldown)";
            case SpecialEffects.BELLS_AND_WHISTLES:
               return "<b>Bells and Whistles:</b> " + "On ability cast, spawn a floating bell on self that regenerates 10 MP per second for 5 seconds " + "within 5 squares. (3s cooldown)";
            case SpecialEffects.SHINY_BELLS_AND_WHISTLES:
               return "<b>Shiny Bells and Whistles:</b> " + "On ability cast, spawn a floating bell on self that regenerates 10 MP per second for 6 seconds " + "within 5 squares. (3s cooldown)";
            case SpecialEffects.CHAOS_CHAOS:
               return "<b>Chaos Chaos:</b> " + "When you hit an enemy, spawn 6 Chaos Flames that shoot a 250 damage shot at the targeted enemy " + "that inflicts Slowed for 4 seconds, then chases the target, " + "dealing 1000 damage within 3 squares. (10s cooldown)";
            case SpecialEffects.METAMORPHOSIS:
               return "<b>Metamorphosis:</b> " + "When you hit an enemy, spawn 6 Chaos Flames that shoot a 250 damage shot at the targeted enemy " + "that inflicts Slowed for 4 seconds, then chases the target, " + "dealing 1000 damage within 3 squares. (8s cooldown)";
            case SpecialEffects.BLOOD_OFFERING:
               return "<b>Blood Offering:</b> " + "When hit by an enemy, channel a skull effect on them, " + "healing 100 HP and dealing 850 damage within 6 squares. (5s cooldown)";
            case SpecialEffects.TRANSMUTATION:
               return "<b>Transmutation:</b> " + "When hit by an enemy, channel a skull effect on them, " + "healing 150 HP and dealing 1700 damage within 6 squares. (5s cooldown)";
            case SpecialEffects.RITUALIST:
               return "<b>Ritualist:</b> " + "Not taking damage for 5 seconds grants mana regeneration, of which is lost upon taking damage.";
            case SpecialEffects.REVENANT:
               return "<b>Revenant:</b> " + "Not taking damage for 3 seconds grants mana regeneration, of which is lost upon taking damage.";
            case SpecialEffects.ACCURSED_BLOOD:
               return "<b>Accursed Blood:</b> " + "All enemies within 7 squares are inflicted with bleed for 900 damage per second. " + "All enemies within 4.5 squares are inflicted with an additional bleed for 1800 damage per second.";
            case SpecialEffects.MELTING_BLOOD:
               return "<b>Melting Blood:</b> " + "All enemies within 7 squares are inflicted with bleed for 1400 damage per second. " + "All enemies within 4.5 squares are inflicted with an additional bleed for 2800 damage per second.";
            case SpecialEffects.FADING:
               return "<b>Fading:</b> " + "Every 8 seconds, become Invulnerable for 1.25 seconds.";
            case SpecialEffects.FORGOTTEN:
               return "<b>Forgotten:</b> " + "Every 6 seconds, become Invulnerable for 1.25 seconds.";
            case SpecialEffects.EQUILIBRIUM:
               return "<b>Equilibrium:</b> " + "Gain a 5% increase to all of your stats, including item stats but excluding stat buffs.";
            case SpecialEffects.OMNISCIENT:
               return "<b>Omniscient:</b> " + "Gain a 10% increase to HP, MP, VIT, WIS, and a 5% increase to DEF, SPD, ATK, DEX. " + "Includes item stats but excludes stat buffs.";
            case SpecialEffects.IMMORTALITY_1:
               return "<b>Immortality?:</b> " + "While equipped, the player is revived on death, and this ring is destroyed. " + "After being revived, the character and all items become shattered and cannot be revived again. " + "Every item that you have in your inventory has a 20% chance to be deleted on revive, " + "including your equipped items.";
            case SpecialEffects.IMMORTALITY_2:
               return "<b>Immortality:</b> " + "While equipped, the player is revived on death, and this ring is destroyed. " + "After being revived, the character and all items become shattered and cannot be revived again.";
            case SpecialEffects.COSMIC_HERMIT:
               return "<b>Cosmic Hermit:</b> " + "Every 10th ability cast restores 25 shield.";
            case SpecialEffects.COSMIC_SAGE:
               return "<b>Cosmic Sage:</b> " + "Every 10th ability cast restores 50 shield.";
            case SpecialEffects.REINFORCED:
               return "<b>Reinforced:</b> " + "While equipped, every 5 Defense grants you 1% damage reduction against Armor Piercing damage. " + "Armor Broken negates this effect. Capped at 20% damage reduction.";
            case SpecialEffects.INDESTRUCTIBLE:
               return "<b>Indestructible:</b> " + "While equipped, every 5 Defense grants you 1% damage reduction against Armor Piercing damage. " + "Every 10 Defense grants an additional 1 Speed. " + "Capped at 20% damage reduction.";
            case SpecialEffects.JUGGERNAUT:
               return "<b>Juggernaut:</b> " + "While Armored, every 10 defense grants 1% damage boost (up to 10%).";
            case SpecialEffects.ABLAZE:
               return "<b>Ablaze:</b> " + "Casting your ability grants a stackable, additive 10% mana cost reduction for 2 seconds.";
            case SpecialEffects.EXACERBATE:
               return "<b>Exacerbate:</b> " + "Critically striking enemies unleashes decapitators around them, smiting them for 25% of your damage within " + "3.5 squares. Using your ability causes this effect to proc 3 times per critical hit for 5 seconds.";
            case SpecialEffects.OGRISH_REGALIA:
               return "<b>Ogrish Regalia:</b> " + "While Armored, 400% of your Defense stat is added to your Shield bash as damage (Capping at 125 Defense). " + "Abilities used while not affected by Armored are 50% cheaper in mana cost.";
            case SpecialEffects.MIGHT_OF_THE_ANCIENTS:
               return "<b>Might of the Ancients:</b> " + "Getting within 4 squares of an enemy fires a shield bash at them " + "that deals 825-975 damage per shot. (1.5 second cooldown)";
            case SpecialEffects.NULLIFY:
               return "<b>Nullify:</b> " + "Damage taken is multiplied by 4x and reflected back to the enemy that dealt it.";
            case SpecialEffects.HIDDEN_TECHNIQUE:
               return "<b>Hidden Technique:</b> " + "Every critical hit landed gives you +3 VIT for 3 seconds, up to +30 VIT.";
            case SpecialEffects.ABSOLUTE_ZERO:
               return "<b>Absolute Zero:</b> " + "Enemies hit by the shield bash explode, shooting out 3 piercing ice shards that deal " + "750 damage and Slow for 3.5 seconds.";
            case SpecialEffects.GLACIAL_TEMPEST:
               return "<b>Glacial Tempest:</b> " + "Using your ability spawns a raging blizzard (up to 3) on cursor that bursts 3 times " + "over the span of 3 seconds. " + "First 2 bursts deal 1000 damage in 6 sqrs, and the final burst deals 2000 damage within 8 sqrs. " + "Additionally, you gain +1 SPD and +2 WIS for every 5 DEF you have while equipped.";
            case SpecialEffects.FEEDING_FRENZY:
               return "<b>Feeding Frenzy:</b> " + "Striking an enemy 4 times with this quiver spawns a Seagull that aggressively chases them " + "for 3 seconds, dealing 750 armor piercing damage every second within 5 squares.";
            case SpecialEffects.DESECRATE:
               return "<b>Desecrate:</b> " + "Hitting an enemy causes you to lob a grenade at them, dealing 1000 armor piercing damage " + "within 3.5 squares. (1 second cooldown)";
            case SpecialEffects.FRENZY:
               return "<b>Frenzy:</b> " + "On shoot, fire an axe toward cursor every 6 seconds. This axe aims repeatedly toward cursor.";
            case SpecialEffects.HYPERSPEED:
               return "<b>Hyperspeed:</b> " + "Not casting this ability within the past 5 seconds will allow you to mount this item. " + "While equipped and mounted, gain an extra 35 speed.";
            case SpecialEffects.VOWOFSILENCE:
               return "<b>Vow of Silence:</b> " + "On ability cast, shoot a stream of projectiles at the nearest enemy for 1s longer than your " + "ability cooldown. The projectile stream density scales off rate of fire and projectile count " + "and the projectile damage scales off mana spent, dealing your original damage at 200 mana spent.";
            case SpecialEffects.GROWTHMATTER:
               return "<b>Growth Matter:</b> " + "Taking a projectile with more than 200 damage grants you a delayed heal " + "for 50% of its damage after 3 seconds. " + "Overflow healing is distributed within 5 squares. (10 second cooldown)";
            case SpecialEffects.FEELINGFINE:
               return "<b>Feeling Fine:</b> " + "Most temprary debuffs received are cleansed at the cost of 33% of your Maximum MP. " + "Quiet costs all of your mana.";
            case SpecialEffects.GLOOPYTOUCH:
               return "<b>Gloopy Touch:</b> " + "Any enemy within 3 squares of you receive the Glooped debuff for 3 seconds, which reduces " + "move speed by 33% and reduces effectiveness of defense by 50%.";
            case SpecialEffects.OOEYGOOEYINFUSION:
               return "<b>Ooey-Gooey Infusion:</b> " + "Shooting 10 times casts lightning in a random direction, " + "dealing 2x the next projectile\'s damage.";
            case SpecialEffects.COSMICCONJURING:
               return "<b>Cosmic Conjuring:</b> " + "Landing a killing blow on an enemy converts the enemy into goo blob familiars. These blobs " + "last for 20 seconds and occasionally shoot 150 damage bullets that slow for 0.4 seconds. " + "Gain 5 MP when one dies.";
            case SpecialEffects.FEEDTHEBEAST:
               return "<b>Feed The Beast:</b> " + "Tossing your trap spawns a feral ooze on cursor that appears on trap landing, " + "dealing impact damage and chasing enemies. The ooze explodes after finding a target, " + "dealing 2500 damage within 7 squares. (3 second cooldown)";
            case SpecialEffects.GOOCLONES:
               return "<b>Goo Clones:</b> " + "Being within one of your ooze decoys shortly after it attacks will heal you for 40 hp. " + "(1.5 second cooldown)";
            case SpecialEffects.MOBIUSEFFECT:
               return "<b>Mobius Goo:</b> " + "Gain 25 vitality. Taking any projectile hit grants you 1 defense and removes 1 vitality, " + "up to 25 max. Lose this boost after not taking damage for 5 seconds.";
            case SpecialEffects.TOTALTRANSFORMATION:
               return "<b>Total Transformation:</b> " + "On ability use, rapidly heal for 600 HP over 3 seconds. (30 second cooldown)";
            case SpecialEffects.SLIMELIGHT:
               return "<b>Slimelight:</b> " + "On hit, 3% chance to zap the closest target near your cursor, dealing " + "damage scaled by wisdom and inflicting Glooped for 2 seconds.";
            case SpecialEffects.FTL:
               return "<b>Faster Than Light:</b> " + "Speedy grants an additional 1.1x speed multiplier.";
            case SpecialEffects.OOMPH:
               return "<b>Oomph:</b> " + "Your main projectile has a 20% chance to deal bonus damage within 3 squares of impact. " + "This bonus damage scales off of enemy defense.";
            case SpecialEffects.BUCKETBRAINED:
               return "<b>Bucket Brained:</b> " + "Upon being hit when below 50% of your HP, activate this ability at no cost. " + "(18 second cooldown)";
            case SpecialEffects.RECONSTITUTION:
               return "<b>Reconstitution:</b> " + "On hit, 1.5% chance to spawn a pink goo ally for 10 seconds, dealing 150 damage " + "and slowing for 0.4 seconds.";
            case SpecialEffects.PINKIMPACT:
               return "<b>Pink Impact:</b> " + "Randomly explode for a random amount of damage within a random amount of squares " + "when taking damage sometimes. She won\'t tell you more.";
            case SpecialEffects.GHOST:
               return "<b>Ghost:</b> " + "Casting your ability will cause your character to dash in the direction of your cursor, " + "this dash will scale with your Speed.";
            case SpecialEffects.DEPOSIT:
               return "<b>Deposit:</b> " + "Not casting this ability within the past 3 seconds will allow you to deposit this item. " + "While equipped and deposited, gain an extra 380 HP and Mana Restoration.";
            case SpecialEffects.FORBIDDEN_MAGIC:
               return "<b>Forbidden Magic:</b> " + "This spell cannot channel spell bombs at cursor location. " + "Instead, the three closest enemies within 3.5 squares of your cursor will be spell-bombed.";
            case SpecialEffects.LIONS_BLOOD:
               return "<b>Lion’s Blood, Cobra’s Bite:</b> " + "While above 50% of your maximum MP, 0.25% of damage dealt to enemies with your weapon " + "is returned as MP. While below 50% of your maximum HP, 2.5% of damage dealt to enemies " + "with your poison is returned as HP.";
            case SpecialEffects.THE_BEST_FRIEND:
               return "<b>The Best Best Friend:</b> " + "Upon death, one of your equipped items is chosen at random to be returned to your gift " + "chests in a shattered state. If a shattered item or an empty equipment slot is chosen, " + "you receive nothing.";
            case SpecialEffects.SWIFT_AS_THE_WIND:
               return "<b>Swift as the Wind:</b> " + "Hitting enemies with this weapon grants you +1 SPD for 5 seconds, stackable up to " + "+30 SPD total. For every 5 points of SPD, gain +1 DEX.";
            case SpecialEffects.SUPERNOVA:
               return "<b>Supernova:</b> " + "Every 25 shots hit spawns a supernova at cursor that explodes into a spread of 5 stars " + "aimed at the enemy closest to cursor after 2 seconds.";
            case SpecialEffects.CATACLYSM:
               return "<b>Cataclysm:</b> " + "Hitting an enemy channels a scepter blast that deals 2000 damage " + "(+10 damage per WIS, capping at 200 WIS) on up to 5 targets (2 second cooldown).";
            case SpecialEffects.HEAVY_ARTILLERY:
               return "<b>Heavy Artillery:</b> " + "Every 8 seconds, a cannon spawns within 5 squares of you. Casting your ability within " + "3 squares of a cannon destroys it and fires a cannonball at the enemy closest " + "to cursor within 10 squares, dealing 10000 damage within 3 squares. " + "Cannons expire after not being used for 30 seconds.";
            case SpecialEffects.LINGERING_WILL:
               return "<b>Lingering Will:</b> " + "Every 60 shots landed fires a volley of three splitting shots that deal 700 damage each. " + "Every shot landed with these shots grants a stacking Berserk for 1.5 seconds, " + "up to a maximum duration of 4.5 seconds.";
            case SpecialEffects.APOCALYPSE:
               return "<b>Apocalypse:</b> " + "Every 3rd critical hit spawns a lightning bolt on the damaged enemy that deals " + "750-1250 damage within 5 squares. On ability cast, transform into a " + "Harbinger of the Apocalypse for 15 seconds. " + "While transformed, +20 Speed, and +300 Maximum Shield (30 second cooldown)";
            case SpecialEffects.MAGICAL_POISON:
               return "<b>Magical Poison:</b> " + "Shots fired by this quiver apply 1000 poison damage over 5 seconds on hit.";
            case SpecialEffects.CURSED_BARRAGE:
               return "<b>Cursed Barrage:</b> " + "For each shot of your ability that you land, gain 0.4 seconds of Berserk and Damaging. " + "Buff duration given by this quiver is capable of stacking, to a maximum of 4.5 seconds.";
            case SpecialEffects.VOID_BARRAGE:
               return "<b>Void Barrage:</b> " + "The closest enemy within 10 squares gets a void arrow fired at them every second, " + "dealing 1000 damage. Each shot of this quiver that hits an enemy heals you for 10 HP.";
            case SpecialEffects.PERSONAL_VESSEL:
               return "<b>Personal Vessel:</b> " + "On ability cast, spawn a friendly Ghost Ship that rotates in a radius of 3.5 squares for " + "10 seconds. The ship fires a spread of 3 cannonballs at the closest enemy every second, " + "dealing 500 armor piercing damage each, and grants allies within 3 squares of it Berserk " + "for 3 seconds (20 second cooldown)";
            case SpecialEffects.MAGI_GENERATOR:
               return "<b>Magi-Generator:</b> " + "Thrown traps spawn a Magi-Generator that’s linked to them, firing a 3000 damage shot at " + "the closest enemy every 2 seconds. If its linked trap expires, so will the Magi-Generator. " + "Additionally, your trap explosion radius is twice as big as its trigger radius.";
            case SpecialEffects.BROAD_GUARD:
               return "<b>Broad Guard:</b> " + "On weapon hit, convert 1% of the damage dealt into Shield (up to 6% of your Maximum Shield). " + "This effect diminishes for each projectile as it hits more enemies.";
            case SpecialEffects.ECHO:
               return "<b>Echo:</b> " + "After 0.3-0.7 seconds, 100% chance (x0.6 per subsequent recast) to recast itself in " + "a slightly offset position.";
            case SpecialEffects.LIGHTNING_ROD:
               return "<b>Lightning Rod:</b> " + "Every 3rd weapon hit calls down a lightning strike, dealing 500 damage (+15 damage per WIS above 60) " + "on up to 3 targets (+1 target per 25 WIS above 75). For 2.5 seconds after casting your ability, " + "the lightning will strike on every hit instead of every 3rd hit (10 second cooldown).";
            case SpecialEffects.COLOSSAL_CURRENT:
               return "<b>Colossal Current:</b> " + "After marking a target, a 3 second timer is placed on them. Targets may be marked again, though " + "their timer will not reset. For each mark placed on a target after the timer expires, 6 lightning " + "strikes will land within 0.75 squares of the target every 0.2 seconds, exploding for 850 damage " + "within 2.5 squares, paralyzing targets within 2.5 squares for 1 second, and shooting 3 projectiles " + "radially that deal 450 damage each.";
            default:
               return null;
         }
      }
      
      public function saveAsPng() : void
      {
         var oldHeight:int = HEIGHT;
         HEIGHT = this.height;
         var newTooltip:EquipmentToolTip = new EquipmentToolTip(this.parent,this.itemData,this.player);
         newTooltip.draw();
         var bitmap:BitmapData = new BitmapData(newTooltip.width - 10,newTooltip.height - 10);
         bitmap.draw(newTooltip);
         HEIGHT = oldHeight;
         newTooltip.dispose();
         var encoded:ByteArray = PNGEncoder.encode(bitmap);
         var fileReference:FileReference = new FileReference();
         var fileName:String = this.itemData.ObjectId;
         fileReference.save(encoded,fileName + ".png");
      }
      
      override public function dispose() : void
      {
         this.icon.bitmapData.dispose();
         this.bagIcon.bitmapData.dispose();
         if(Boolean(this.player))
         {
            this.player.currentEquipToolTip = null;
         }
      }
      
      public function drawDesc() : void
      {
         var index:int = 0;
         this.descText = new SimpleText(14,11776947,false,WIDTH - 10);
         var text:String = Boolean(this.itemData.Description) ? this.itemData.Description : "";
         while(text.indexOf("\\n") != -1)
         {
            index = int(text.indexOf("\\n"));
            text = text.slice(0,index) + "\n" + text.slice(index + 2);
         }
         this.descText.htmlText += text;
         this.descText.wordWrap = true;
         this.descText.useTextDimensions();
         if(Boolean(Parameters.data.toolTipOutline))
         {
            this.descText.filters = FilterUtil.getTextOutlineFilter();
         }
         else
         {
            this.descText.filters = FilterUtil.getTextShadowFilter();
         }
         this.descText.x = 5;
         this.descText.y = this.icon.height + 3;
         this.addToolTip(this.descText);
      }
      
      public function calculateProjectileRange(proj:ProjectileDesc, doReforge:Boolean = false) : Number
      {
         var realSpeed:Number = proj.RealSpeed;
         var speed:Number = realSpeed / 10000;
         var lifetime:Number = proj.LifetimeMS;
         var rang:Number = speed * lifetime;
         var rang2:Number = 0;
         if(doReforge)
         {
            realSpeed = Boolean(this.itemData.Reforge) && this.itemData.Reforge.ItemType == "Weapon" ? proj.RealSpeed + this.itemData.getStatChange(proj.RealSpeed,"ShotSpeed") : proj.RealSpeed;
            speed = realSpeed / 10000;
            lifetime = Boolean(this.itemData.Reforge) && this.itemData.Reforge.ItemType == "Weapon" ? proj.LifetimeMS + this.itemData.getStatChange(proj.LifetimeMS,"LifetimeMS") : proj.LifetimeMS;
            rang2 = speed * lifetime;
         }
         if(proj.Radius > 0)
         {
            return proj.Radius;
         }
         if(proj.Acceleration == 0 || lifetime < proj.AccelerationDelay)
         {
            return rang2 != 0 ? (rang2 - rang <= -0.1 || rang2 - rang >= 0.1 ? rang2 : rang) : rang;
         }
         var end:Point = new Point();
         ProjectileGO.GetPositionAt(lifetime,0,0,proj,0,0,end,this.itemData);
         return Math.sqrt(end.x * end.x + end.y * end.y);
      }
      
      public function scrollUp() : void
      {
         if(!this.scrollable)
         {
            return;
         }
         if(this.amountScrolled - SCROLL_VELOCITY < 0 && this.toolTipContainer.y + this.amountScrolled >= 0)
         {
            return;
         }
         this.scrollHelperFadeOut();
         this.toolTipContainer.y += SCROLL_VELOCITY;
         this.amountScrolled += SCROLL_VELOCITY;
      }
      
      public function scrollDown() : void
      {
         if(!this.scrollable)
         {
            return;
         }
         if(this.floorLine.y + this.amountScrolled <= 600 - SCROLL_VELOCITY && this.amountScrolled - SCROLL_VELOCITY < 0)
         {
            return;
         }
         this.scrollHelperFadeOut();
         this.toolTipContainer.y -= SCROLL_VELOCITY;
         this.amountScrolled -= SCROLL_VELOCITY;
      }
      
      public function resetScroll() : void
      {
         if(!this.scrollable || this.amountScrolled == 0)
         {
            return;
         }
         this.toolTipContainer.y -= this.amountScrolled;
         this.amountScrolled = 0;
      }
      
      public function addToolTip(displayObject:DisplayObject) : void
      {
         var mask:Sprite = null;
         if(displayObject.y + displayObject.height > HEIGHT)
         {
            mask = new Sprite();
            mask.graphics.beginFill(0,1);
            mask.graphics.drawRect(0,0,WIDTH,HEIGHT);
            mask.graphics.endFill();
            displayObject.mask = mask;
            this.equipContainer.addChild(mask);
         }
         this.toolTipContainer.addChild(displayObject);
      }
      
      private function addContainers() : void
      {
         this.toolTipContainer = new Sprite();
         this.equipContainer = new Sprite();
         this.equipContainer.addChild(this.toolTipContainer);
         addChild(this.equipContainer);
      }
      
      private function drawIcon() : void
      {
         var timer:Timer = null;
         if(Boolean(this.itemData.Animation))
         {
            this.frames = this.itemData.Animation.Frames;
         }
         if(this.frames != null)
         {
            if(this.currFrame == -1)
            {
               this.currFrame = 0;
            }
            timer = new Timer(1000 * this.frames[this.currFrame].Time);
            timer.addEventListener(TimerEvent.TIMER,this.animateTexture);
            timer.start();
         }
         else
         {
            this.currFrame = -1;
         }
         var tex:BitmapData = this.itemData.Texture.getRedrawnTexture(this.itemData.ObjectType,70,0,true);
         tex = BitmapUtil.cropToBitmapData(tex,4,4,tex.width - 8,tex.height - 8);
         this.icon = new Bitmap(tex);
         this.addToolTip(this.icon);
      }
      
      private function drawDisplayName() : void
      {
         var prefix:String;
         var text:String = TooltipHelper.getSpecialityText(this.itemData);
         var color:uint = text != "Untiered" ? this.specialityColor : 11776947;
         this.displayText = new SimpleText(17,color,false,WIDTH - (this.icon.width + 30));
         prefix = "";
         if(this.itemData.Reforge != null)
         {
            prefix = this.itemData.Reforge.Name + " ";
         }
         this.displayText.text = this.itemData.DisplayId != null ? prefix + this.itemData.DisplayId : "Unknown";
         this.displayText.setAutoSize(TextFieldAutoSize.LEFT);
         this.displayText.setBold(true);
         this.displayText.useTextDimensions();
         if(Boolean(Parameters.data.toolTipOutline))
         {
            this.displayText.filters = FilterUtil.getTextOutlineFilter();
         }
         else
         {
            this.displayText.filters = FilterUtil.getTextShadowFilter();
         }
         this.displayText.x = this.icon.width;
         this.displayText.y = (this.icon.height - this.displayText.height) / 4 - 3;
         this.addToolTip(this.displayText);
         if(this.itemData.Rainbow)
         {
            TierUtil.makeAnimatedColor(this,function():void
            {
               displayText.setColor(MoreColorUtil.globalRainbowColor);
            });
         }
         if(this.itemData.Null)
         {
            TierUtil.makeAnimatedColor(this,function():void
            {
               displayText.setColor(MoreColorUtil.globalNullColor);
            });
         }
         if(this.itemData.H5)
         {
            TierUtil.makeAnimatedColor(this,function():void
            {
               displayText.setColor(MoreColorUtil.globalAwokenHunterColor);
            });
         }
      }
      
      private function drawSpeciality() : void
      {
         var text:String = TooltipHelper.getSpecialityText(this.itemData);
         this.specialityText = new SimpleText(14,this.specialityColor);
         this.specialityText.text = text;
         this.specialityText.useTextDimensions();
         if(Boolean(Parameters.data.toolTipOutline))
         {
            this.specialityText.filters = FilterUtil.getTextOutlineFilter();
         }
         else
         {
            this.specialityText.filters = FilterUtil.getTextShadowFilter();
         }
         this.specialityText.x = this.displayText.x;
         this.specialityText.y = this.displayText.y + this.displayText.height - 4;
         this.addToolTip(this.specialityText);
         if(this.itemData.Rainbow)
         {
            TierUtil.makeAnimatedColor(this,function():void
            {
               specialityText.setColor(MoreColorUtil.globalRainbowColor);
            });
         }
         if(this.itemData.Null)
         {
            TierUtil.makeAnimatedColor(this,function():void
            {
               specialityText.setColor(MoreColorUtil.globalNullColor);
            });
         }
         if(this.itemData.H5)
         {
            TierUtil.makeAnimatedColor(this,function():void
            {
               specialityText.setColor(MoreColorUtil.globalAwokenHunterColor);
            });
         }
      }
      
      private function drawNullQuestionMarks() : void
      {
         var count:int;
         var i:int;
         var text:SimpleText = null;
         var genText:String = null;
         var n:int = 0;
         this.nullQuestionMarks_ = [];
         count = Math.random() * 7 + 3;
         for(i = 0; i < count; i++)
         {
            genText = "";
            for(n = 0; n < Math.random() * 15 + 2; n++)
            {
               genText += "?";
            }
            if(Math.random() > 0.9)
            {
               genText += "???????????????????";
            }
            if(Math.random() > 0.95)
            {
               genText += "??????????????????????????????????????";
            }
            text = new SimpleText(14,this.specialityColor);
            text.text = genText;
            text.useTextDimensions();
            if(Boolean(Parameters.data.toolTipOutline))
            {
               text.filters = FilterUtil.getTextOutlineFilter();
            }
            else
            {
               text.filters = FilterUtil.getTextShadowFilter();
            }
            text.x = Math.random() * this.width;
            text.y = Math.random() * this.height;
            this.addToolTip(text);
            this.nullQuestionMarks_.push(text);
         }
         TierUtil.makeAnimatedColor(this,function():void
         {
            var questionMarkText:SimpleText = null;
            for each(questionMarkText in nullQuestionMarks_)
            {
               questionMarkText.setColor(MoreColorUtil.globalNullColor);
            }
         });
      }
      
      private function drawTier() : void
      {
         this.tierLabel = TierUtil.getTierTag(this.itemData,16);
         if(!this.tierLabel)
         {
            return;
         }
         if(Boolean(Parameters.data.toolTipOutline))
         {
            this.tierLabel.filters = FilterUtil.getTextOutlineFilter();
         }
         else
         {
            this.tierLabel.filters = FilterUtil.getTextShadowFilter();
         }
         this.tierLabel.x = WIDTH - this.tierLabel.width;
         this.tierLabel.y = this.displayText.y;
         this.addToolTip(this.tierLabel);
      }
      
      private function drawBagIcon() : void
      {
         var tex:BitmapData = GetBagTexture(this.itemData.BagType,40);
         tex = BitmapUtil.cropToBitmapData(tex,4,4,tex.width - 8,tex.height - 8);
         this.bagIcon = new Bitmap(tex);
         if(Boolean(this.tierLabel))
         {
            this.bagIcon.x = this.tierLabel.x - (this.bagIcon.width - this.tierLabel.width) / 2;
            this.bagIcon.y = this.tierLabel.y + this.tierLabel.height - 9;
         }
         else
         {
            this.bagIcon.x = WIDTH - this.bagIcon.width;
            this.bagIcon.y = (this.icon.height - this.bagIcon.height) / 2;
         }
         this.addToolTip(this.bagIcon);
      }
      
      private function makeInformationData() : void
      {
         if(this.itemData.TransformResult != "")
         {
            if(this.itemData.Transformed)
            {
               this.information += "Transformed from: " + noDiffColor(this.itemData.TransformResult) + "\n";
            }
            else
            {
               this.information += noDiffColor("This item can be transformed") + "\n";
            }
         }
         if(this.itemData.LimitedUses > 0)
         {
            this.information += "This item has limited amount of uses\n";
         }
         if(this.itemData.AwakenedEffects != null && !this.itemData.Awakened)
         {
            this.information += textColor2("This item can be awakened",TooltipHelper.AWAKENED_COLOR) + "\n";
         }
         if(this.itemData.Shattered)
         {
            this.information += textColor("This item has been shattered\n","#58C5FF");
         }
         if(this.itemData.SnowballerReward)
         {
            this.information += textColor("SnowBaller Event 2023 Reward\n","#98B8D1");
         }
         if(this.itemData.RewardFor != "")
         {
            this.information += "Reward for: <b>" + noDiffColor(this.itemData.RewardFor) + "</b>\n";
         }
         if(this.itemData.ReskinOf != "")
         {
            this.information += "Reskin of: " + noDiffColor(this.itemData.ReskinOf) + "\n";
         }
         this.makeExtraTooltipData();
         this.makeCustomIEData();
      }
      
      private function drawInformationData() : void
      {
         if(this.information == "")
         {
            return;
         }
         this.drawLine1();
         this.informationText = new SimpleText(14,11776947,false,WIDTH - 10);
         this.informationText.wordWrap = true;
         this.informationText.htmlText += this.information;
         this.informationText.useTextDimensions();
         if(Boolean(Parameters.data.toolTipOutline))
         {
            this.informationText.filters = FilterUtil.getTextOutlineFilter();
         }
         else
         {
            this.informationText.filters = FilterUtil.getTextShadowFilter();
         }
         this.informationText.x = this.descText.x;
         this.informationText.y = this.line1.y + this.line1.height + 3;
         this.addToolTip(this.informationText);
      }
      
      private function makeExtraTooltipData() : void
      {
         var data:CustomToolTipData = null;
         if(!this.itemData.CustomToolTipDataList || this.itemData.CustomToolTipDataList.length < 1)
         {
            return;
         }
         var str:String = "";
         for(var i:int = 0; i < this.itemData.CustomToolTipDataList.length; i++)
         {
            data = this.itemData.CustomToolTipDataList[i];
            if(data.Name != "")
            {
               str += data.Name + ": ";
            }
            str += TooltipHelper.wrapInFontTag(data.Description,data.DescriptionColorString) + "\n";
         }
         this.information += str;
      }
      
      private function makeCustomIEData() : void
      {
         var eff:int = 0;
         var demonEyesCooldown:int = 0;
         var wismoddedCooldown:Number = NaN;
         var chance:int = 0;
         var bleedDamage:int = 0;
         var wisModBleed:int = 0;
         if(!this.itemData.ItemEffects)
         {
            return;
         }
         var str:String = "";
         for each(eff in this.itemData.ItemEffects)
         {
            switch(eff)
            {
               case SpecialEffects.DEMON_EYES:
                  demonEyesCooldown = 5;
                  wismoddedCooldown = ApplyDemonEyesWisMod(demonEyesCooldown,this.player);
                  if(wismoddedCooldown != demonEyesCooldown)
                  {
                     str += "Demon Eyes Cooldown: " + GetWisModText(demonEyesCooldown,ApplyDemonEyesWisMod(demonEyesCooldown,this.player),TooltipHelper.NO_DIFF_COLOR) + " secs";
                  }
                  else
                  {
                     str += "Demon Eyes Cooldown: " + TooltipHelper.wrapInFontTag("" + demonEyesCooldown,TooltipHelper.NO_DIFF_COLOR) + " secs";
                  }
                  break;
               case SpecialEffects.SOULFLAMES:
                  if(this.player)
                  {
                     chance = Math.min(100,50 + (this.player.wisdom_ - 50) / 2);
                     str += "Soulflame Chance: " + noDiffColor(chance + "%\n");
                     if(this.player.hasItemEffect(SpecialEffects.ELVISH_MASTERY))
                     {
                        str += "Soulflames Damage: " + noDiffColor(1250) + " " + TooltipHelper.wrapInFontTag("(x1.25)","#57d2e0") + "\n";
                        str += "Brazier Damage: " + noDiffColor(1250) + " " + TooltipHelper.wrapInFontTag("(x1.25)","#57d2e0") + "\n";
                     }
                  }
                  break;
               case SpecialEffects.INCINERATION:
                  if(this.player)
                  {
                     bleedDamage = 750;
                     wisModBleed = bleedDamage + Math.floor(this.player.wisdom_ / 35) * 500;
                     str += "Bleed: " + GetWisModText(bleedDamage,wisModBleed,TooltipHelper.NO_DIFF_COLOR) + " damage/sec\n";
                  }
                  break;
               case SpecialEffects.GORGONS_GAZE:
                  if(this.player)
                  {
                     if(this.player.hasItemEffect(SpecialEffects.ELVISH_MASTERY))
                     {
                        str += "Gorgon\'s Gaze Damage: " + noDiffColor(3750) + " " + TooltipHelper.wrapInFontTag("(x1.25)","#57d2e0") + "\n";
                     }
                  }
                  break;
            }
         }
         this.information += str;
      }
      
      private function makeAttributes() : void
      {
         this.attributes = "";
         this.makeProjAttributes();
         this.makeRageEffects();
         this.makeActivateEffects();
         this.makeEquipStatBoosts();
         this.makeInventoryStatBoosts();
         this.makeGlobalAttributes();
      }
      
      private function makeProjAttributes() : void
      {
         var proj:ProjectileDesc = this.itemData.Projectiles[0];
         var proj2:ProjectileDesc = Boolean(this.equipData) ? this.equipData.Projectiles[0] : null;
         if(!proj)
         {
            return;
         }
         var explodeProj:ProjectileDesc = Boolean(proj.Explode) ? proj.Explode.Projectile : null;
         var explodeProj2:ProjectileDesc = Boolean(this.equipData) && Boolean(proj2) ? (Boolean(proj2.Explode) ? proj2.Explode.Projectile : null) : null;
         this.makeProjCount();
         this.makeProjEffects(proj,proj2);
         explodeProj && this.makeExplodeProjEffects(explodeProj,explodeProj2);
         this.makeProjDamage(proj,proj2);
         this.makeProjRange(proj,proj2);
         this.makeProjRoF(proj,proj2);
         this.makeProjArcGap(proj,proj2);
         this.makeProjProperties(proj,proj2);
      }
      
      private function makeProjCount() : void
      {
         this.attributes += "Shots: " + this.getProjCountTextFull() + "\n";
      }
      
      private function getProjCountTextFull() : String
      {
         var i:int = 0;
         var counts:Vector.<int> = new Vector.<int>();
         var counts2:Vector.<int> = new Vector.<int>();
         var explode:ExplodeDesc = this.itemData.Projectiles[0].Explode;
         var explode2:ExplodeDesc = this.equipData != null ? (this.equipData.Projectiles[0] != null ? this.equipData.Projectiles[0].Explode : null) : null;
         counts.push(this.itemData.NumProjectiles);
         if(Boolean(this.equipData))
         {
            counts2.push(this.equipData.NumProjectiles);
         }
         if(explode != null)
         {
            counts.push(explode.NumProjectiles);
         }
         if(explode2 != null)
         {
            counts2.push(explode2.NumProjectiles);
         }
         for(i = 0; explode != null; i++)
         {
            if(explode.Projectile.Explode == null)
            {
               break;
            }
            explode = explode.Projectile.Explode;
            counts.push(explode.NumProjectiles);
         }
         for(i = 0; explode2 != null; i++)
         {
            if(explode2.Projectile.Explode == null)
            {
               break;
            }
            explode2 = explode2.Projectile.Explode;
            counts2.push(explode2.NumProjectiles);
         }
         var ret:String = GetProjCountText(counts);
         var color:String = GetProjCountColor(counts,counts2);
         return TooltipHelper.wrapInFontTag(ret,color);
      }
      
      private function makeExplodeProjEffects(proj:ProjectileDesc, proj2:ProjectileDesc) : void
      {
         var condEff:CondEffect = null;
         var duration:Number = NaN;
         var color:String = null;
         var i2:int = 0;
         var duration2:Number = NaN;
         if(!proj.Effects || proj.Effects.length < 1)
         {
            return;
         }
         this.attributes += TooltipHelper.getPluralText(proj.Effects.length,"Split Shot Effect") + ":\n";
         for(var i:int = 0; i < proj.Effects.length; i++)
         {
            condEff = proj.Effects[i];
            duration = MathUtil2.roundTo(condEff.DurationMS / 1000,2);
            color = TooltipHelper.NO_DIFF_COLOR;
            if(proj2 && proj.Effects && proj.Effects.length > 0)
            {
               i2 = GetConditionEffectIndex(condEff.Effect,proj2.Effects);
               if(i2 != -1)
               {
                  duration2 = MathUtil2.roundTo(proj2.Effects[i2].DurationMS / 1000,2);
                  color = TooltipHelper.getTextColor(duration - duration2);
               }
               else
               {
                  color = TooltipHelper.BETTER_COLOR;
               }
            }
            else if(this.usableBy)
            {
               color = TooltipHelper.BETTER_COLOR;
            }
            this.attributes += "  -Inflicts " + TooltipHelper.wrapInFontTag(condEff.getTextEffectName(),color) + " for " + TooltipHelper.wrapInFontTag(String(duration),color) + " secs" + "\n";
         }
      }
      
      private function makeProjEffects(proj:ProjectileDesc, proj2:ProjectileDesc) : void
      {
         var condEff:CondEffect = null;
         var duration:Number = NaN;
         var color:String = null;
         var i2:int = 0;
         var duration2:Number = NaN;
         if(!proj.Effects || proj.Effects.length < 1)
         {
            return;
         }
         this.attributes += TooltipHelper.getPluralText(proj.Effects.length,"Shot Effect") + ":\n";
         for(var i:int = 0; i < proj.Effects.length; i++)
         {
            condEff = proj.Effects[i];
            duration = MathUtil2.roundTo(condEff.DurationMS / 1000,2);
            color = TooltipHelper.NO_DIFF_COLOR;
            if(proj2 && proj.Effects && proj.Effects.length > 0)
            {
               i2 = GetConditionEffectIndex(condEff.Effect,proj2.Effects);
               if(i2 != -1)
               {
                  duration2 = MathUtil2.roundTo(proj2.Effects[i2].DurationMS / 1000,2);
                  color = TooltipHelper.getTextColor(duration - duration2);
               }
               else
               {
                  color = TooltipHelper.BETTER_COLOR;
               }
            }
            else if(this.usableBy)
            {
               color = TooltipHelper.BETTER_COLOR;
            }
            this.attributes += "  -Inflicts " + TooltipHelper.wrapInFontTag(condEff.getTextEffectName(),color) + " for " + TooltipHelper.wrapInFontTag(String(duration),color) + " secs" + "\n";
         }
      }
      
      private function makeProjDamage(proj:ProjectileDesc, proj2:ProjectileDesc) : void
      {
         var fame:int = 0;
         var minD2:int = 0;
         var maxD2:int = 0;
         var avg1:Number = NaN;
         var avg2:Number = NaN;
         var altColor:String = null;
         var altAvg1:Number = NaN;
         var altAvg2:Number = NaN;
         var damageColor:String = null;
         var explodeMinD:int = 0;
         var explodeMaxD:int = 0;
         var explodeBoost:String = null;
         var damageString:String = null;
         var minD:int = proj.MinDamage;
         var maxD:int = proj.MaxDamage;
         if(Boolean(this.player) && this.itemData.hasItemEffect(SpecialEffects.FAME_KINGPIN))
         {
            fame = this.player.fame_;
            minD = maxD = fameScaleDamage(fame,minD);
         }
         var boostText:String = "";
         if(ItemConstants.isAbility(this.itemData) && this.player && this.player.hasItemEffect(SpecialEffects.ELVISH_MASTERY))
         {
            minD *= this.player.getElvishMasteryMult(this.itemData);
            maxD *= this.player.getElvishMasteryMult(this.itemData);
            boostText += " " + TooltipHelper.wrapInFontTag("(x" + this.player.getElvishMasteryMult(this.itemData) + ")","#57d2e0");
         }
         if(this.itemData.EssenceUpgrades.DamageBoost > 0)
         {
            boostText += " ";
            boostText += TooltipHelper.wrapInFontTag("(+" + this.itemData.EssenceUpgrades.DamageBoost + ")",MoreColorUtil.toHtmlString(TooltipHelper.AWAKENED_COLOR));
         }
         var reforgeDmgText:String = "";
         if(this.itemData.Reforge != null && this.itemData.Reforge.ItemType == "Weapon")
         {
            reforgeDmgText = this.itemData.getStatIncreaseText(minD,maxD,false,"MinDamage","MaxDamage");
            if(reforgeDmgText != "")
            {
               minD += this.itemData.getStatChange(minD,"MinDamage");
               maxD += this.itemData.getStatChange(maxD,"MaxDamage");
            }
         }
         else if(Boolean(this.itemData.Reforge) && this.itemData.Reforge.ItemType == "Ability")
         {
            reforgeDmgText = this.itemData.getStatIncreaseText(minD,maxD,true,"AbilityPower");
            if(reforgeDmgText != "")
            {
               minD += this.itemData.getStatChange(minD,"AbilityPower");
               maxD += this.itemData.getStatChange(maxD,"AbilityPower");
            }
         }
         boostText += " " + reforgeDmgText;
         var color:String = TooltipHelper.NO_DIFF_COLOR;
         if(Boolean(proj2))
         {
            minD2 = proj2.MinDamage;
            maxD2 = proj2.MaxDamage;
            if(Boolean(this.player) && this.itemData.hasItemEffect(SpecialEffects.FAME_KINGPIN))
            {
               fame = this.player.fame_;
               minD2 = maxD2 = fameScaleDamage(fame,minD2);
            }
            if(ItemConstants.isAbility(this.itemData) && this.player && this.player.hasItemEffect(SpecialEffects.ELVISH_MASTERY))
            {
               minD2 *= this.player.getElvishMasteryMult(this.itemData);
               maxD2 *= this.player.getElvishMasteryMult(this.itemData);
            }
            if(reforgeDmgText != "")
            {
               minD2 += this.itemData.getStatChange(minD2,"MinDamage");
               maxD2 += this.itemData.getStatChange(maxD2,"MaxDamage");
            }
            avg1 = (minD + maxD) / 2;
            avg2 = (minD2 + maxD2) / 2;
            color = TooltipHelper.getTextColor(avg1 - avg2);
         }
         else if(this.usableBy)
         {
            color = TooltipHelper.BETTER_COLOR;
         }
         this.attributes += "Damage: " + TooltipHelper.wrapInFontTag(minD == maxD ? String(minD) : minD + " - " + maxD,color) + boostText;
         if(proj.AlternativeMaxDamage > 0 && proj.AlternativeMinDamage > 0)
         {
            altColor = TooltipHelper.NO_DIFF_COLOR;
            if(Boolean(proj2))
            {
               altAvg1 = (proj.AlternativeMinDamage + proj.AlternativeMaxDamage) / 2;
               altAvg2 = (proj2.AlternativeMinDamage + proj2.AlternativeMaxDamage) / 2;
               altColor = TooltipHelper.getTextColor(altAvg1 - altAvg2);
            }
            else if(this.usableBy)
            {
               altColor = TooltipHelper.BETTER_COLOR;
            }
            this.attributes += " -> " + TooltipHelper.wrapInFontTag(proj.AlternativeMinDamage == proj.AlternativeMaxDamage ? String(proj.AlternativeMinDamage) : proj.AlternativeMinDamage + " - " + proj.AlternativeMaxDamage,altColor);
         }
         if(Boolean(proj.Explode))
         {
            damageColor = proj.Explode.Projectile.ArmorPiercing ? TooltipHelper.SPECIAL_COLOR : TooltipHelper.NO_DIFF_COLOR;
            explodeMinD = proj.Explode.Projectile.MinDamage;
            explodeMaxD = proj.Explode.Projectile.MaxDamage;
            explodeBoost = "";
            if(ItemConstants.isAbility(this.itemData) && this.player && this.player.hasItemEffect(SpecialEffects.ELVISH_MASTERY))
            {
               explodeMinD *= this.player.getElvishMasteryMult(this.itemData);
               explodeMaxD *= this.player.getElvishMasteryMult(this.itemData);
               explodeBoost += " " + textColor("(x" + this.player.getElvishMasteryMult(this.itemData) + ")","#57d2e0");
            }
            damageString = explodeMinD == explodeMaxD ? String(explodeMinD) : explodeMinD + " - " + explodeMaxD;
            this.attributes += TooltipHelper.wrapInFontTag(" => ",TooltipHelper.NO_DIFF_COLOR);
            this.attributes += TooltipHelper.wrapInFontTag(damageString,damageColor) + explodeBoost;
         }
         this.attributes += "\n";
      }
      
      private function makeProjRange(proj:ProjectileDesc, proj2:ProjectileDesc) : void
      {
         var range2:Number = NaN;
         var explodeColor:String = null;
         var explodeRange:Number = NaN;
         var rangeIncrease:Number = NaN;
         var range:Number = TooltipHelper.getFormattedRangeString(this.calculateProjectileRange(proj,true));
         if(proj.Boomerang)
         {
            range = Round(range / 2,2);
         }
         var color:String = TooltipHelper.NO_DIFF_COLOR;
         if(Boolean(proj2))
         {
            range2 = TooltipHelper.getFormattedRangeString(this.calculateProjectileRange(proj2,true));
            if(proj2.Boomerang)
            {
               range2 = Round(range2 / 2,2);
            }
            color = TooltipHelper.getTextColor(range - range2);
         }
         else if(this.usableBy)
         {
            color = TooltipHelper.BETTER_COLOR;
         }
         this.attributes += "Range: " + TooltipHelper.wrapInFontTag(String(range),color);
         if(Boolean(proj.Explode))
         {
            explodeColor = TooltipHelper.NO_DIFF_COLOR;
            explodeRange = TooltipHelper.getFormattedRangeString(this.calculateProjectileRange(proj.Explode.Projectile));
            this.attributes += TooltipHelper.wrapInFontTag(" => " + String(explodeRange),explodeColor);
         }
         if(Boolean(this.itemData.Reforge) && this.itemData.Reforge.ItemType == "Weapon")
         {
            rangeIncrease = TooltipHelper.getFormattedRangeString(range - this.calculateProjectileRange(proj,false));
            if(rangeIncrease >= 0.1 || rangeIncrease <= -0.1)
            {
               this.attributes += TooltipHelper.wrapInFontTag(" (" + this.itemData.getChangeText(rangeIncrease,false) + ")",this.itemData.getColorFromTier());
            }
         }
         this.attributes += "\n";
      }
      
      private function makeProjRoF(proj:ProjectileDesc, proj2:ProjectileDesc) : void
      {
         var boostPercentage:int = 0;
         var newRof2:Number = NaN;
         var reforgeBoost2:Number = NaN;
         var rof2:int = 0;
         if(this.itemData.RateOfFire == -1)
         {
            return;
         }
         var awakenedColor:String = MoreColorUtil.toHtmlString(TooltipHelper.AWAKENED_COLOR);
         var tierColor:String = this.itemData.getColorFromTier();
         var rofChangeText:String = "";
         var rofStat:Number = this.itemData.RateOfFire;
         var reforgeBoost:Number = 0;
         var essenceRof:Number = this.itemData.EssenceUpgrades.RateOfFire;
         if(essenceRof > 0)
         {
            rofChangeText = "(" + GetSign(essenceRof) + Math.round(essenceRof * 100) + "%)";
            rofChangeText = TooltipHelper.wrapInFontTag(rofChangeText,awakenedColor);
         }
         if(Boolean(this.itemData.Reforge) && this.itemData.Reforge.ItemType == "Weapon")
         {
            reforgeBoost = this.itemData.getStatChange(rofStat,"RateofFire");
            rofStat += reforgeBoost;
         }
         if(reforgeBoost != 0)
         {
            boostPercentage = int(reforgeBoost * 100);
            rofChangeText += TooltipHelper.wrapInFontTag(" (" + this.itemData.getChangeText(boostPercentage) + "%)",tierColor);
         }
         var rof:int = Math.round(rofStat * 100);
         var color:String = TooltipHelper.NO_DIFF_COLOR;
         if(Boolean(this.equipData))
         {
            newRof2 = this.equipData.RateOfFire;
            reforgeBoost2 = 0;
            if(Boolean(this.equipData.Reforge) && this.equipData.Reforge.ItemType == "Weapon")
            {
               reforgeBoost2 = this.equipData.getStatChange(this.equipData.RateOfFire,"RateofFire");
            }
            newRof2 += reforgeBoost2;
            rof2 = Math.round(newRof2 * 100);
            color = TooltipHelper.getTextColor(rof - rof2);
         }
         else if(this.usableBy)
         {
            color = TooltipHelper.BETTER_COLOR;
         }
         this.attributes += "Rate of Fire: " + TooltipHelper.wrapInFontTag(rof.toFixed(0) + "%",color) + " " + rofChangeText + "\n";
      }
      
      private function makeProjArcGap(proj:ProjectileDesc, proj2:ProjectileDesc) : void
      {
         var arc2:Number = NaN;
         var arc:Number = this.itemData.ArcGap;
         var essenceArc:Number = this.itemData.EssenceUpgrades.ArcGap;
         if(arc == 0 && essenceArc == 0)
         {
            return;
         }
         var color:String = TooltipHelper.NO_DIFF_COLOR;
         if(Boolean(this.equipData))
         {
            arc2 = this.equipData.ArcGap;
            color = TooltipHelper.getTextColor(arc2 - arc);
         }
         else if(this.usableBy)
         {
            color = TooltipHelper.BETTER_COLOR;
         }
         var arcModifier:String = "";
         if(essenceArc != 0)
         {
            arcModifier += TooltipHelper.wrapInFontTag(" (" + WithSign(essenceArc) + ")",MoreColorUtil.toHtmlString(TooltipHelper.AWAKENED_COLOR));
         }
         this.attributes += "Arc Gap: " + TooltipHelper.wrapInFontTag(String(arc),color) + arcModifier + "\n";
      }
      
      private function makeProjProperties(proj:ProjectileDesc, proj2:ProjectileDesc) : void
      {
         var s:String = null;
         if(proj.ArmorPiercing)
         {
            this.attributes += TooltipHelper.wrapInFontTag("Shots ignore defense of target",TooltipHelper.SPECIAL_COLOR) + "\n";
         }
         if(proj.Boomerang)
         {
            this.attributes += TooltipHelper.wrapInFontTag("Shots boomerang",TooltipHelper.NO_DIFF_COLOR) + "\n";
         }
         if(proj.MultiHit)
         {
            this.attributes += TooltipHelper.wrapInFontTag("Shots hit multiple targets",TooltipHelper.NO_DIFF_COLOR) + "\n";
         }
         if(proj.PassesCover)
         {
            this.attributes += TooltipHelper.wrapInFontTag("Shots pass through obstacles",TooltipHelper.NO_DIFF_COLOR) + "\n";
         }
         if(proj.Parametric)
         {
            this.attributes += TooltipHelper.wrapInFontTag("Shots are parametric",TooltipHelper.NO_DIFF_COLOR) + "\n";
         }
         if(proj.Radius > 0)
         {
            s = proj.Circles == 1 ? "" : "s";
            this.attributes += noDiffColor("Shots circle around " + proj.Circles + " time" + s) + "\n";
         }
         if(proj.Explode != null && proj.Explode.AimAtCursor)
         {
            this.attributes += noDiffColor("Split shots are aimed at cursor\n");
         }
      }
      
      private function makeRageEffects() : void
      {
         var color:String = null;
         var b:Object = null;
         var statId:int = 0;
         var amount:int = 0;
         var statString:String = null;
         if(!this.itemData.MaskDesc)
         {
            return;
         }
         var mask1:MaskDescription = this.itemData.MaskDesc;
         var mask2:MaskDescription = Boolean(this.equipData) ? this.equipData.MaskDesc : null;
         var durationColor:String = TooltipHelper.NO_DIFF_COLOR;
         if(Boolean(mask2))
         {
            durationColor = TooltipHelper.getTextColor(mask1.Duration - mask2.Duration);
         }
         this.attributes += "Mask: " + noDiffColor("Applies Rage for ") + textColor(mask1.Duration,durationColor) + noDiffColor(" secs") + "\n";
         this.attributes += "Rage: " + noDiffColor("Gain small amount of Rage every time you hit a boss") + "\n";
         var maskBoosts1:Dictionary = mask1.MaskBoosts;
         var maskBoosts2:Dictionary = Boolean(mask2) ? mask2.MaskBoosts : null;
         this.attributes += "During Rage:\n";
         for(b in maskBoosts1)
         {
            statId = int(b);
            amount = int(maskBoosts1[b]);
            statString = Stats.fromId(statId);
            color = TooltipHelper.NO_DIFF_COLOR;
            if(Boolean(maskBoosts2) && statId in maskBoosts2)
            {
               color = TooltipHelper.getTextColor(amount - maskBoosts2[statId]);
            }
            else if(maskBoosts1 != maskBoosts2)
            {
               color = TooltipHelper.getTextColor(amount);
            }
            this.attributes += TooltipHelper.wrapInFontTag(GetSign(amount) + amount + " " + statString,color) + "\n";
         }
      }
      
      private function makeActivateEffects() : void
      {
         var ae:ActivateEffect = null;
         var wisModded:ModdedEffect = null;
         var statColor:String = null;
         var amountColor:String = null;
         var rangeColor:String = null;
         var durationColor:String = null;
         var conditionColor:String = null;
         var totalDmgColor:String = null;
         var radiusColor:String = null;
         var impactDmgColor:String = null;
         var condDurationColor:String = null;
         var maxTargetsColor:String = null;
         var healAmountColor:String = null;
         var stat:String = null;
         var condition:String = null;
         var ae2:ActivateEffect = null;
         var itemDataAes:Array = null;
         var equipDataAes:Array = null;
         var ae1:ActivateEffect = null;
         var wisModded2:ModdedEffect = null;
         var impactDmgString:String = null;
         var impactDmgString2:String = null;
         var name:String = null;
         var className:String = null;
         var skinXml:XML = null;
         var s:String = null;
         var text:String = null;
         var pieceName:String = null;
         var endS:String = null;
         var classXml:XML = null;
         var effs:Vector.<ActivateEffect> = new Vector.<ActivateEffect>();
         for each(ae in this.itemData.ActivateEffects)
         {
            if(!(!ae.EffectName || ae.EffectName == "" || IGNORE_AE.indexOf(ae.EffectName) != -1))
            {
               effs.push(ae);
            }
         }
         if(effs.length < 1)
         {
            return;
         }
         var heldAbility:Boolean = this.itemData.Held;
         this.attributes += "On Use:\n";
         this.attributes += "<span class=\'aeIn\'>";
         for each(ae in effs)
         {
            if(ae.DosesReq > 0)
            {
               this.attributes += TooltipHelper.wrapInFontTag("(Requires at least " + ae.DosesReq + " doses)","#E0761E");
            }
            if(ae.NodeReq != -1)
            {
               this.attributes += TooltipHelper.wrapInFontTag("(Requires blessing)","#E0761E");
            }
            if(ae.DosesReq > 0 || ae.NodeReq != -1)
            {
               this.attributes += "\n";
            }
            this.attributes += "-";
            wisModded = new ModdedEffect(ae,this.itemData,this.player);
            statColor = TooltipHelper.NO_DIFF_COLOR;
            amountColor = TooltipHelper.NO_DIFF_COLOR;
            rangeColor = TooltipHelper.NO_DIFF_COLOR;
            durationColor = TooltipHelper.NO_DIFF_COLOR;
            conditionColor = TooltipHelper.NO_DIFF_COLOR;
            totalDmgColor = TooltipHelper.NO_DIFF_COLOR;
            radiusColor = TooltipHelper.NO_DIFF_COLOR;
            impactDmgColor = TooltipHelper.NO_DIFF_COLOR;
            condDurationColor = TooltipHelper.NO_DIFF_COLOR;
            maxTargetsColor = TooltipHelper.NO_DIFF_COLOR;
            healAmountColor = TooltipHelper.NO_DIFF_COLOR;
            stat = Stats.fromId(ae.Stats);
            condition = getConditionName(ae.ConditionEffect);
            if(this.usableBy && this.equipData && this.equipData.ActivateEffects && this.equipData.ActivateEffects.length > 0 && this.itemData != this.equipData)
            {
               itemDataAes = [];
               equipDataAes = [];
               for each(ae1 in this.itemData.ActivateEffects)
               {
                  if(ae1.EffectName == ae.EffectName)
                  {
                     itemDataAes.push(ae1);
                  }
               }
               for each(ae2 in this.equipData.ActivateEffects)
               {
                  if(ae2.EffectName == ae.EffectName)
                  {
                     equipDataAes.push(ae2);
                  }
               }
               ae2 = null;
               for each(ae2 in equipDataAes)
               {
                  if(itemDataAes.indexOf(ae) == equipDataAes.indexOf(ae2))
                  {
                     break;
                  }
               }
            }
            if(Boolean(ae2))
            {
               wisModded2 = new ModdedEffect(ae2,this.equipData,this.player);
               if(!HasAEStat(stat,ae.EffectName,this.equipData.ActivateEffects))
               {
                  statColor = TooltipHelper.BETTER_COLOR;
               }
               if(!HasAECondition(condition,ae.EffectName,this.equipData.ActivateEffects))
               {
                  conditionColor = TooltipHelper.BETTER_COLOR;
               }
               amountColor = getColor(wisModded.Amount,wisModded2.Amount);
               rangeColor = getColor(wisModded.Range,wisModded2.Range);
               durationColor = getColor(wisModded.DurationMs,wisModded2.DurationMs);
               totalDmgColor = getColor(wisModded.TotalDamage,wisModded2.TotalDamage);
               radiusColor = getColor(wisModded.Radius,wisModded2.Radius);
               impactDmgColor = getColor(ae.ImpactDmg,ae2.ImpactDmg);
               condDurationColor = getColor(wisModded.EffectDuration,wisModded2.EffectDuration);
               maxTargetsColor = getColor(wisModded.MaxTargets,wisModded2.MaxTargets);
               healAmountColor = getColor(wisModded.HealAmount,wisModded2.HealAmount);
            }
            if(!ae2 && this.itemData != this.equipData && this.usableBy)
            {
               statColor = TooltipHelper.BETTER_COLOR;
               amountColor = TooltipHelper.BETTER_COLOR;
               rangeColor = TooltipHelper.BETTER_COLOR;
               durationColor = TooltipHelper.BETTER_COLOR;
               conditionColor = TooltipHelper.BETTER_COLOR;
               totalDmgColor = TooltipHelper.BETTER_COLOR;
               radiusColor = TooltipHelper.BETTER_COLOR;
               impactDmgColor = TooltipHelper.BETTER_COLOR;
               condDurationColor = TooltipHelper.BETTER_COLOR;
               maxTargetsColor = TooltipHelper.BETTER_COLOR;
               healAmountColor = TooltipHelper.BETTER_COLOR;
            }
            switch(ae.EffectName)
            {
               case ActivationType.GENERIC_ACTIVATE:
                  this.attributes += BuildGenericAE(ae,wisModded,rangeColor,durationColor,condition,conditionColor);
                  break;
               case ActivationType.INCREMENT_STAT:
                  this.attributes += "Increases " + noDiffColor(stat) + " by " + noDiffColor(ae.Amount);
                  break;
               case ActivationType.HEAL:
                  this.attributes += "Heals " + textColor(wisModded.Amount,amountColor) + wisModded.ModAmount + " HP";
                  break;
               case ActivationType.MAGIC:
                  this.attributes += "Heals " + textColor(wisModded.Amount,amountColor) + wisModded.ModAmount + " MP";
                  break;
               case ActivationType.HEAL_NOVA:
                  this.attributes += "Heals {0} in {1} sqrs".replace("{0}",textColor(wisModded.Amount,amountColor) + wisModded.ModAmount).replace("{1}",textColor(wisModded.Range,rangeColor) + wisModded.ModRange);
                  break;
               case ActivationType.STAT_BOOST_SELF:
                  this.attributes += "On Self: {0} {1} for {2} secs".replace("{0}",textColor(WithSign(wisModded.Amount),amountColor) + wisModded.ModAmount).replace("{1}",textColor(stat,statColor)).replace("{2}",textColor(wisModded.DurationSec,durationColor) + wisModded.ModDurationSec);
                  break;
               case ActivationType.STAT_BOOST_AURA:
                  this.attributes += "On Allies: {0} {1} in {2} sqrs for {3} secs".replace("{0}",textColor(WithSign(wisModded.Amount),amountColor) + wisModded.ModAmount).replace("{1}",textColor(stat,statColor)).replace("{2}",textColor(wisModded.Range,rangeColor) + wisModded.ModRange).replace("{3}",textColor(wisModded.DurationSec,durationColor) + wisModded.ModDurationSec);
                  break;
               case ActivationType.BULLET_NOVA:
                  this.attributes += "Spell: " + textColor(ae.Amount,amountColor) + " shots";
                  break;
               case ActivationType.COND_EFFECT_SELF:
                  this.attributes += "On Self: {0} for {1} secs".replace("{0}",textColor(condition,conditionColor)).replace("{1}",textColor(wisModded.DurationSec,durationColor) + wisModded.ModDurationSec);
                  break;
               case ActivationType.COND_EFFECT_AURA:
                  this.attributes += "On Allies: {0} in {1} sqrs for {2} secs".replace("{0}",textColor(condition,conditionColor)).replace("{1}",textColor(wisModded.Range,rangeColor) + wisModded.ModRange).replace("{2}",textColor(wisModded.DurationSec,durationColor) + wisModded.ModDurationSec);
                  break;
               case ActivationType.TELEPORT:
                  this.attributes += "Teleports to cursor";
                  break;
               case ActivationType.POISON_GRENADE:
                  impactDmgString = ae.ImpactDmg > 0 ? " (" + textColor(ae.ImpactDmg,impactDmgColor) + " on impact)" : "";
                  this.attributes += "Poison: Deals {0} damage{1} in {2} sqrs for {3} secs".replace("{0}",textColor(wisModded.TotalDamage,totalDmgColor) + wisModded.ModTotalDamage).replace("{1}",impactDmgString).replace("{2}",textColor(wisModded.Radius,radiusColor) + wisModded.ModRadius).replace("{3}",textColor(wisModded.DurationSec,durationColor) + wisModded.ModDurationSec);
                  break;
               case ActivationType.VAMPIRE_BLAST:
                  this.attributes += "Skull: Heals {0} HP dealing {1} damage in {2} sqrs".replace("{0}",textColor(wisModded.HealAmount,healAmountColor) + wisModded.ModHealAmount).replace("{1}",textColor(wisModded.TotalDamage,totalDmgColor) + wisModded.ModTotalDamage).replace("{2}",textColor(wisModded.Radius,radiusColor) + wisModded.ModRadius);
                  break;
               case ActivationType.TRAP:
                  this.attributes += "Trap: Deals {0} damage in {1} sqrs; Lasts for {2} secs".replace("{0}",textColor(wisModded.TotalDamage,totalDmgColor) + wisModded.ModTotalDamage).replace("{1}",textColor(wisModded.Radius,radiusColor) + wisModded.ModRadius).replace("{2}",textColor(ae.DurationSec,durationColor));
                  if(ae.EffectDuration > 0)
                  {
                     this.attributes += "\n    Applies {0} for {1} secs".replace("{0}",textColor(!condition ? "Slowed" : condition,conditionColor)).replace("{1}",textColor(wisModded.EffectDuration,condDurationColor) + wisModded.ModEffectDuration);
                  }
                  break;
               case ActivationType.STASIS_BLAST:
                  this.attributes += "Stasis enemies within " + noDiffColor("3 sqrs") + " of cursor for " + textColor(wisModded.DurationSec,durationColor) + wisModded.ModDurationSec + " secs";
                  break;
               case ActivationType.DECOY:
                  this.attributes += "Decoy: Lasts for " + textColor(wisModded.DurationSec,durationColor) + wisModded.ModDurationSec + " secs";
                  if(ae.Target == "cursor")
                  {
                     this.attributes += ", walks at cursor direction";
                  }
                  if(ae.Center == "cursor")
                  {
                     this.attributes += ", spawns at cursor and stays";
                  }
                  if(ae.AngleOffset != 0)
                  {
                     this.attributes += ", " + noDiffColor(ae.AngleOffset) + " degree offset";
                  }
                  break;
               case ActivationType.LIGHTNING:
                  this.attributes += "Lightning: Targets {0} enemies dealing {1} damage".replace("{0}",textColor(wisModded.MaxTargets,maxTargetsColor) + wisModded.ModMaxTargets).replace("{1}",textColor(wisModded.TotalDamage,totalDmgColor) + wisModded.ModTotalDamage);
                  if(Boolean(condition))
                  {
                     this.attributes += "\n    Applies {0} for {1} secs".replace("{0}",textColor(condition,conditionColor)).replace("{1}",textColor(wisModded.EffectDuration,condDurationColor) + wisModded.ModEffectDuration);
                  }
                  break;
               case ActivationType.MAGIC_NOVA:
                  this.attributes += "Heals {0} MP in {1} sqrs".replace("{0}",textColor(wisModded.Amount,amountColor) + wisModded.ModAmount).replace("{1}",textColor(wisModded.Range,rangeColor) + wisModded.ModRange);
                  break;
               case ActivationType.DAMAGE_BLAST:
                  this.attributes += "AoE: Deals {0} damage in {1} sqrs".replace("{0}",textColor(wisModded.TotalDamage,totalDmgColor) + wisModded.ModTotalDamage).replace("{1}",textColor(wisModded.Radius,radiusColor) + wisModded.ModRadius);
                  break;
               case ActivationType.POISON_BLAST:
                  impactDmgString2 = ae.ImpactDmg > 0 ? " (" + textColor(ae.ImpactDmg,impactDmgColor) + " on impact)" : "";
                  this.attributes += "AoE: Deals {0} damage{1} in {2} sqrs for {3} secs".replace("{0}",textColor(wisModded.TotalDamage,totalDmgColor) + wisModded.ModTotalDamage).replace("{1}",impactDmgString2).replace("{2}",textColor(wisModded.Radius,radiusColor) + wisModded.ModRadius).replace("{3}",textColor(wisModded.DurationSec,durationColor) + wisModded.ModDurationSec);
                  break;
               case ActivationType.REMOVE_NEG_COND:
                  this.attributes += "On Allies: Purifies all debuffs in " + textColor(wisModded.Range,rangeColor) + wisModded.ModRange + " sqrs";
                  break;
               case ActivationType.REMOVE_NEG_COND_SELF:
                  this.attributes += "On Self: Purifies all debuffs";
                  break;
               case ActivationType.BACKPACK:
                  this.attributes += "Unlocks the backpack";
                  break;
               case ActivationType.UNLOCK_SATCHEL:
                  this.attributes += "Unlocks the materials satchel";
                  break;
               case ActivationType.CHANGE_NAME_COLOR:
                  this.attributes += "Changes the <font color=\"#" + MathUtil2.decimalToHex(ae.Color,6) + "\">color</font> of your name in chat";
                  break;
               case ActivationType.UNLOCK_CHAR:
                  this.attributes += "Unlocks an extra character slot";
                  break;
               case ActivationType.UNLOCK_VAULT:
                  this.attributes += "Unlocks an extra vault chest";
                  break;
               case ActivationType.CRATE:
                  this.attributes += "Opens a loot crate";
                  break;
               case ActivationType.UNLOCK_SKIN:
                  name = "Invalid Skin!";
                  className = "Invalid Class!";
                  skinXml = ObjectLibrary.xmlLibrary_[ae.SkinType];
                  if(Boolean(skinXml))
                  {
                     name = skinXml.@id;
                     classXml = ObjectLibrary.xmlLibrary_[int(skinXml.PlayerClassType)];
                     if(Boolean(classXml))
                     {
                        className = classXml.@id;
                     }
                  }
                  this.attributes += "Unlocks the " + noDiffColor(name) + " skin for " + noDiffColor(className);
                  break;
               case ActivationType.XP_BOOST:
                  this.attributes += "x2 XP while active";
                  break;
               case ActivationType.LT_BOOST:
                  this.attributes += "+1 tier from loot while active";
                  break;
               case ActivationType.LD_BOOST:
                  this.attributes += noDiffColor("x" + String(1 + ae.Amount / 100)) + " loot drop chance while active";
                  break;
               case ActivationType.ADD_CURRENCY:
                  if(ae.Amount > 0)
                  {
                     this.attributes += "Adds " + noDiffColor(ae.Amount) + " " + ae.CurrencyName + " to your account";
                  }
                  else
                  {
                     this.attributes += "Removes " + ae.Amount + " " + ae.CurrencyName + " from your account";
                  }
                  break;
               case ActivationType.RESET_SKILL_TREE:
                  this.attributes += "Resets skill tree progress";
                  break;
               case ActivationType.SPELL_GRENADE:
                  this.attributes += "Airborne Spell: " + textColor(ae.Amount,amountColor) + " shots";
                  break;
               case ActivationType.ALLY:
                  this.attributes += "Summons a " + noDiffColor(ae.ObjectId) + " for " + noDiffColor(ae.DurationSec) + " seconds";
                  break;
               case ActivationType.PURIFY_MADNESS:
                  this.attributes += "Purifies " + noDiffColor("King\'s Madness") + " and resets Madness buildup";
                  break;
               case ActivationType.ATTACKING_VINES:
                  this.attributes += "Spawns a cluster of three vines at cursor for 3 seconds";
                  break;
               case ActivationType.RARE_EVENTS_BOOST:
                  this.attributes += "Boosts a Realm\'s chance to spawn Rare Events by " + noDiffColor("+" + String(ae.Chance * 100) + "%");
                  break;
               case ActivationType.NEXT_REALM_EVENT:
                  this.attributes += "When used in Realm, forces the next Realm event to be " + noDiffColor(ae.ObjectId);
                  break;
               case ActivationType.CHAOS_FIRES:
                  this.attributes += "Summons 4 flames for " + noDiffColor("3.5 secs");
                  break;
               case ActivationType.KING_GEMS_1:
                  this.attributes += "Summons either a " + noDiffColor("Blue") + " or " + noDiffColor("Green") + " gem that orbits player for " + noDiffColor("5 secs");
                  break;
               case ActivationType.KING_GEMS_2:
                  this.attributes += "Summons either a " + noDiffColor("Red") + " or " + noDiffColor("Yellow") + " gem that orbits decoy for " + noDiffColor("5 secs");
                  break;
               case ActivationType.ADD_SKILL_POINTS:
                  s = ae.Amount > 1 ? "s" : "";
                  this.attributes += "Adds " + noDiffColor(ae.Amount) + " skill point" + s + " to your character";
                  break;
               case ActivationType.QUEST_TELEPORT:
                  this.attributes += "Teleports you to your quest when used in Realm";
                  break;
               case ActivationType.SKILL_XP_BOOST:
                  this.attributes += noDiffColor("x" + String(ae.Amount / 100 + 1)) + " Skill XP while active";
                  break;
               case ActivationType.INCREMENT_LB:
                  this.attributes += "Increases " + noDiffColor("Lootboost") + " by " + noDiffColor(String(ae.Amount));
                  break;
               case ActivationType.PILL:
                  switch(ae.Id)
                  {
                     case "Blackout":
                        this.attributes += "Resets your Birthsign and sends you to the Dark Room";
                        break;
                     case "Cyanide":
                        this.attributes += "Kills you, and gives various fame bonuses";
                        break;
                     case "Shadow":
                        this.attributes += "The House of Despair calls your name!";
                        break;
                     case "Trumpet":
                        this.attributes += "Opens almost anything from the Realm... almost... everything...";
                  }
                  break;
               case ActivationType.PERMA_PET:
                  this.attributes += "Spawns a cosmetic {0} pet".replace("{0}",noDiffColor(ae.ObjectId));
                  break;
               case ActivationType.MAGICIAN_BUNNY:
                  text = "";
                  if(ae.Id == "Brown")
                  {
                     text = "Throws Bunny Magician at cursor, which lasts for {DURATION}";
                  }
                  else
                  {
                     text = "Spawns Bunny Magician for {DURATION}";
                  }
                  this.attributes += text.replace("{DURATION}",noDiffColor(ae.DurationSec) + " secs");
                  break;
               case ActivationType.GOLDEN_WATCH:
                  if(this.itemData.Awakened)
                  {
                     this.attributes += "Activates the passive effect";
                  }
                  else
                  {
                     this.attributes += "Tells you the exact time until next Auction";
                  }
                  break;
               case ActivationType.MONKE_MODE:
                  this.attributes += "Activates Monkey’s Curse for " + noDiffColor("20 mins") + "";
                  break;
               case ActivationType.RAID_KEY_PIECE:
                  pieceName = ae.Type;
                  this.attributes += "Activates the " + noDiffColor(pieceName) + " raid altar in Nexus";
                  break;
               case ActivationType.HELL_KEY_CREATE:
                  this.attributes += "Activates all three raid altars in Nexus and starts the Hell Raid";
                  break;
               case ActivationType.TEMPORARY_LB:
                  this.attributes += "Grants {AMOUNT} loot boost for {DURATION} secs {STACKING}".replace("{AMOUNT}",noDiffColor(ae.Amount + "%")).replace("{DURATION}",noDiffColor(ae.DurationSec)).replace("{STACKING}",ae.NoStack ? "(no stacking)" : "(stackable)");
                  break;
               case ActivationType.THROW_SNOWBALL:
                  this.attributes += "Snowball: Steals {IMPACT} from players within {RADIUS} and adds {AMOUNT} for every player hit".replace("{IMPACT}",noDiffColor(ae.ImpactDmg + " point(s)")).replace("{AMOUNT}",noDiffColor(ae.Amount + " point(s)")).replace("{RADIUS}",noDiffColor(ae.Radius + " sqrs"));
                  break;
               case ActivationType.BARRAGE:
                  endS = ae.Amount > 1 ? "s" : "";
                  if(heldAbility)
                  {
                     this.attributes += ("Barrage: Fire {AMOUNT} set{S} of shots at enemy closest to cursor " + "every {DURATION} sec").replace("{AMOUNT}",noDiffColor(ae.Amount)).replace("{DURATION}",noDiffColor(ae.DurationSec)).replace("{S}",endS);
                     break;
                  }
                  this.attributes += ("Barrage: Fire {AMOUNT} set{S} of shots at enemy closest to cursor over " + "{DURATION} sec").replace("{AMOUNT}",noDiffColor(wisModded.Amount) + wisModded.ModAmount).replace("{DURATION}",noDiffColor(wisModded.DurationSec) + wisModded.ModDurationSec).replace("{S}",endS);
                  break;
               case ActivationType.GRENADE:
                  this.attributes += "Grenade: Deals {DAMAGE} damage within {RADIUS} sqrs; {AIR_TIME} sec air time".replace("{DAMAGE}",noDiffColor(ae.ImpactDmg)).replace("{RADIUS}",noDiffColor(ae.Radius)).replace("{AIR_TIME}",noDiffColor(Round(ae.AirDurationMS / 1000,1)));
                  break;
               case ActivationType.DEATH_BOOST:
                  this.attributes += "Activates +{AMOUNT}% death loot boost for {DURATION} secs".replace("{AMOUNT}",noDiffColor(this.itemData.DeathBoostAmount)).replace("{DURATION}",noDiffColor(ae.DurationSec));
                  break;
               case ActivationType.SKILL_XP:
                  this.attributes += "Grants your character +{AMOUNT} SXP".replace("{AMOUNT}",noDiffColor(ae.Amount));
                  break;
               case ActivationType.HALLOWEEN_CANDY:
                  this.attributes += "This candy is added to the {TYPE} candy pool, to empower Realm Event dungeons".replace("{TYPE}",noDiffColor(ae.Type));
            }
            if(ae.OnRelease)
            {
               this.attributes += " (On release)";
            }
            else if(heldAbility)
            {
               this.attributes += " (While held)";
            }
            if(!LastElement(ae,this.itemData.ActivateEffects))
            {
               this.attributes += "\n";
            }
            else
            {
               this.attributes += "</span>\n";
            }
         }
      }
      
      private function makeEquipStatBoosts() : void
      {
         var statBoost:StatBoost = null;
         var statBoost2:StatBoost = null;
         var finalStatIncreases2:Dictionary = null;
         var boostText:String = null;
         var statId:int = 0;
         var original:int = 0;
         var modifierIncrease:Number = NaN;
         var key:Object = null;
         var reforge:ReforgeStats = null;
         var reforge2:ReforgeStats = null;
         var amount:Number = NaN;
         var amount2:Number = NaN;
         var amountColor:String = null;
         var sign:String = null;
         var coloredStatName:String = null;
         var coloredAmount:String = null;
         if((this.itemData.StatBoosts == null || this.itemData.StatBoosts.length < 1) && (this.itemData.Reforge == null || !this.itemData.reforgeHasBasicStat()) && (CountKeys(this.itemData.EssenceUpgrades.StatBoosts) == 0 || this.itemData.Essences == 0) && CountKeys(this.GetIEEquipBonuses()) <= 0)
         {
            return;
         }
         this.attributes += "On Equip:\n";
         var finalStatIncreases:Dictionary = new Dictionary();
         var modifierText:Dictionary = new Dictionary();
         for each(statBoost in this.itemData.StatBoosts)
         {
            if(finalStatIncreases[statBoost.Stat] == null)
            {
               finalStatIncreases[statBoost.Stat] = 0;
            }
            finalStatIncreases[statBoost.Stat] += Stats.convert(statBoost.Stat,statBoost.Amount);
         }
         finalStatIncreases2 = new Dictionary();
         if(Boolean(this.equipData))
         {
            for each(statBoost2 in this.equipData.StatBoosts)
            {
               if(finalStatIncreases2[statBoost2.Stat] == null)
               {
                  finalStatIncreases2[statBoost2.Stat] = 0;
               }
               finalStatIncreases2[statBoost2.Stat] += statBoost2.Amount;
            }
         }
         var awakenedColor:String = MoreColorUtil.toHtmlString(TooltipHelper.AWAKENED_COLOR);
         var reforgeTierColor:String = this.itemData.getColorFromTier();
         if(Boolean(this.itemData.Reforge))
         {
            for each(reforge in this.itemData.Reforge.Stats[this.itemData.reforgeTier()])
            {
               statId = Stats.fromName(reforge.StatName);
               original = int(int(finalStatIncreases[statId]) || 0);
               modifierIncrease = this.itemData.getStatInc(original,reforge.Value,reforge.Percent);
               if(modifierIncrease != 0)
               {
                  if(finalStatIncreases[statId] == null)
                  {
                     finalStatIncreases[statId] = 0;
                  }
                  finalStatIncreases[statId] += modifierIncrease;
                  boostText = TooltipHelper.wrapInFontTag(" (" + WithSign(modifierIncrease) + ")",reforgeTierColor);
                  modifierText[statId] = (modifierText[statId] || "") + boostText;
               }
            }
         }
         if(Boolean(this.equipData) && Boolean(this.equipData.Reforge))
         {
            for each(reforge2 in this.equipData.Reforge.Stats[this.equipData.reforgeTier()])
            {
               statId = Stats.fromName(reforge2.StatName);
               original = int(int(finalStatIncreases2[statId]) || 0);
               if(finalStatIncreases2[statId] == null)
               {
                  finalStatIncreases2[statId] = 0;
               }
               modifierIncrease = this.itemData.getStatInc(original,reforge2.Value,reforge2.Percent);
               finalStatIncreases2[statId] += modifierIncrease;
            }
         }
         for(key in this.itemData.EssenceUpgrades.StatBoosts)
         {
            statId = int(key);
            modifierIncrease = Stats.convert(statId,this.itemData.EssenceUpgrades.StatBoosts[statId]);
            if(modifierIncrease != 0)
            {
               if(finalStatIncreases[statId] == null)
               {
                  finalStatIncreases[statId] = 0;
               }
               finalStatIncreases[statId] += modifierIncrease;
               boostText = TooltipHelper.wrapInFontTag(" (" + WithSign(modifierIncrease) + Stats.getSign(statId) + ")",awakenedColor);
               modifierText[statId] = (modifierText[statId] || "") + boostText;
            }
         }
         if(Boolean(this.equipData))
         {
            for(key in this.equipData.EssenceUpgrades.StatBoosts)
            {
               statId = int(key);
               modifierIncrease = Number(this.equipData.EssenceUpgrades.StatBoosts[statId]);
               if(finalStatIncreases2[statId] == null)
               {
                  finalStatIncreases2[statId] = 0;
               }
               finalStatIncreases2[statId] += modifierIncrease;
            }
         }
         var ieBonuses:Dictionary = this.GetIEEquipBonuses();
         for(key in ieBonuses)
         {
            statId = int(key);
            modifierIncrease = Stats.convert(statId,ieBonuses[statId]);
            if(finalStatIncreases[statId] == null)
            {
               finalStatIncreases[statId] = 0;
            }
            finalStatIncreases[statId] += modifierIncrease;
         }
         if(this.itemData.hasItemEffect(SpecialEffects.HOARDER) && this.itemData.DemonicSacrifices > 0)
         {
            applyHoarderStats(this.itemData.DemonicSacrifices,finalStatIncreases,modifierText);
         }
         if(this.equipData && this.equipData.hasItemEffect(SpecialEffects.HOARDER) && this.equipData.DemonicSacrifices > 0)
         {
            applyHoarderStats(this.equipData.DemonicSacrifices,finalStatIncreases2);
         }
         var orderedFinalStats:Vector.<int> = new Vector.<int>();
         for each(statBoost in this.itemData.StatBoosts)
         {
            if(orderedFinalStats.indexOf(statBoost.Stat) == -1)
            {
               orderedFinalStats.push(statBoost.Stat);
            }
         }
         for(key in finalStatIncreases)
         {
            statId = int(key);
            if(orderedFinalStats.indexOf(statId) == -1)
            {
               orderedFinalStats.push(statId);
            }
         }
         for each(statId in orderedFinalStats)
         {
            amount = Number(finalStatIncreases[statId]);
            amount2 = Number(Number(finalStatIncreases2[statId]) || 0);
            boostText = modifierText[statId] || "";
            amountColor = this.usableBy ? TooltipHelper.BETTER_COLOR : TooltipHelper.NO_DIFF_COLOR;
            if(Stats.getColor(statId) != null)
            {
               amountColor = Stats.getColor(statId);
            }
            else if(this.equipData == this.itemData)
            {
               amountColor = TooltipHelper.NO_DIFF_COLOR;
            }
            else if(amount2 != 0)
            {
               amountColor = TooltipHelper.getTextColor(amount - amount2);
            }
            else if(amount < 0)
            {
               amountColor = TooltipHelper.WORSE_COLOR;
            }
            sign = Stats.getSign(statId);
            coloredStatName = TooltipHelper.wrapInFontTag(Stats.fromId(statId),amountColor);
            coloredAmount = TooltipHelper.wrapInFontTag(WithSign(amount) + sign,amountColor);
            this.attributes += "  " + coloredAmount + " " + coloredStatName + boostText + "\n";
         }
      }
      
      private function GetIEEquipBonuses() : Dictionary
      {
         var eff:int = 0;
         var bonuses:Dictionary = new Dictionary();
         for each(eff in this.itemData.ItemEffects)
         {
            switch(eff)
            {
               case SpecialEffects.PROTECTION_TECHNIQUE:
                  bonuses[140] = (bonuses[140] == null ? 0 : bonuses[140]) + 100;
                  break;
               case SpecialEffects.VITAL_POINT:
                  bonuses[138] = (bonuses[138] == null ? 0 : bonuses[138]) + 100;
                  break;
               case SpecialEffects.DRAW_BACK:
                  bonuses[140] = (bonuses[140] == null ? 0 : bonuses[140]) + 75;
                  break;
               case SpecialEffects.BLAZE:
                  bonuses[138] = (bonuses[138] == null ? 0 : bonuses[138]) + 100;
                  break;
               case SpecialEffects.CREMATION:
                  bonuses[138] = (bonuses[138] == null ? 0 : bonuses[138]) + 150;
                  break;
               case SpecialEffects.DEFENSE_PROTOCOL:
                  bonuses[116] = (bonuses[116] == null ? 0 : bonuses[116]) + 100;
                  break;
               case SpecialEffects.DEFENSE_MATRIX:
                  bonuses[116] = (bonuses[116] == null ? 0 : bonuses[116]) + 150;
                  break;
               case SpecialEffects.COSMIC_HERMIT:
                  bonuses[116] = (bonuses[116] == null ? 0 : bonuses[116]) + 25;
                  break;
               case SpecialEffects.COSMIC_SAGE:
                  bonuses[116] = (bonuses[116] == null ? 0 : bonuses[116]) + 50;
                  break;
            }
         }
         return bonuses;
      }
      
      private function makeInventoryStatBoosts() : void
      {
         var statBoost:StatBoost = null;
         var statName:String = null;
         var amount:Number = NaN;
         if((!this.itemData.InventoryStatBoosts || this.itemData.InventoryStatBoosts.length < 1) && this.itemData.LootBoost == 0)
         {
            return;
         }
         var finalString:String = "";
         finalString += "While in Inventory:\n";
         var amountColor:String = TooltipHelper.NO_DIFF_COLOR;
         var lootBoost:int = this.itemData.LootBoost;
         if(lootBoost != 0)
         {
            if(this.usableBy)
            {
               amountColor = TooltipHelper.getTextColor(lootBoost);
            }
            finalString += "  ";
            finalString += TooltipHelper.wrapInFontTag(GetSign(lootBoost) + lootBoost + "%",amountColor) + " " + TooltipHelper.wrapInFontTag("Loot Boost",amountColor) + "\n";
         }
         if((!this.itemData.InventoryStatBoosts || this.itemData.InventoryStatBoosts.length < 1) && lootBoost == 0)
         {
            return;
         }
         for each(statBoost in this.itemData.InventoryStatBoosts)
         {
            if(!(statBoost.AwakenedOnly && !this.itemData.Awakened))
            {
               statName = Stats.fromId(statBoost.Stat);
               amount = Stats.convert(statBoost.Stat,statBoost.Amount);
               if(amount < 0)
               {
                  amountColor = TooltipHelper.WORSE_COLOR;
               }
               else if(this.usableBy)
               {
                  amountColor = TooltipHelper.BETTER_COLOR;
               }
               else
               {
                  amountColor = TooltipHelper.NO_DIFF_COLOR;
               }
               finalString += "  ";
               finalString += TooltipHelper.wrapInFontTag(GetSign(amount) + amount,amountColor) + " " + TooltipHelper.wrapInFontTag(statName,amountColor) + "\n";
            }
         }
         if(finalString.indexOf("+") == -1 && finalString.indexOf("-") == -1)
         {
            return;
         }
         this.attributes += finalString;
      }
      
      private function makeGlobalAttributes() : void
      {
         if(this.itemData.Doses > 0)
         {
            this.makeItemDoses();
         }
         if(this.itemData.FameBonus > 0)
         {
            this.makeItemFameBonus();
         }
         if(this.itemData.MpEndCost <= 0 && this.itemData.MpCost > 0)
         {
            this.makeItemMpCost();
         }
         else if(this.itemData.MpEndCost > 0)
         {
            this.makeItemMpEndCost();
         }
         if(this.itemData.MpDrainCost != -1)
         {
            this.makeItemMpDrainCost();
         }
         if(this.itemData.HpCost != -1)
         {
            this.makeItemHpCost();
         }
         if(this.itemData.HpDrainCost != -1)
         {
            this.makeItemHpDrainCost();
         }
         if(this.itemData.Usable || this.itemData.Reusable)
         {
            this.makeItemCooldown();
         }
         if(this.itemData.HunterLevel != -1)
         {
            this.makeHunterItemInfo();
         }
         else if(this.itemData.HarvestedSouls > 0)
         {
            this.makeHarvestedSouls(0);
         }
         if(this.itemData.Durability > 0)
         {
            this.makeBoosterDesc();
         }
         if(this.itemData.EpicKey)
         {
            this.makeEpicKeyDesc();
         }
      }
      
      private function makeItemDoses() : void
      {
         var doses2:int = 0;
         var maxDoses:int = this.itemData.MaxDoses;
         var doses:int = this.itemData.Doses;
         var color:String = TooltipHelper.NO_DIFF_COLOR;
         if(this.equipData && this.equipData.Doses > 0 && this.equipData.DisplayId == this.itemData.DisplayId)
         {
            doses2 = this.equipData.Doses;
            color = TooltipHelper.getTextColor(doses - doses2);
         }
         if(doses == maxDoses)
         {
            color = TooltipHelper.BETTER_COLOR;
         }
         this.attributes += "Doses: " + textColor(doses,color) + textColor("/" + maxDoses,color) + "\n";
      }
      
      private function makeItemFameBonus() : void
      {
         var fame2:int = 0;
         var fame:int = this.itemData.FameBonus;
         var color:String = TooltipHelper.NO_DIFF_COLOR;
         if(Boolean(this.equipData) && this.equipData.FameBonus > 0)
         {
            fame2 = this.equipData.FameBonus;
            color = TooltipHelper.getTextColor(fame - fame2);
         }
         else if(this.usableBy)
         {
            color = TooltipHelper.BETTER_COLOR;
         }
         this.attributes += "Fame Bonus: " + TooltipHelper.wrapInFontTag(fame + "%",color) + "\n";
      }
      
      private function makeItemMpCost() : void
      {
         var finalCost2:int = 0;
         var awakenedColor:String = null;
         if(!this.itemData.Usable)
         {
            return;
         }
         var mpCost:int = this.itemData.MpCost;
         var mpMult:int = Boolean(this.player) ? this.player.mpMult : 100;
         var multChange:int = mpCost * (mpMult / 100) - mpCost;
         var reforgeInc:int = Boolean(this.itemData.Reforge) ? int(this.itemData.getStatChange(mpCost + multChange,"ManaCost")) : 0;
         var finalCost:int = Boolean(this.player) ? this.player.getMpCost(this.itemData) : mpCost + multChange + reforgeInc;
         var color:String = TooltipHelper.NO_DIFF_COLOR;
         if(Boolean(this.equipData) && this.equipData.MpCost > 0)
         {
            finalCost2 = this.player.getMpCost(this.equipData);
            color = TooltipHelper.getTextColor(finalCost2 - finalCost);
         }
         else if(this.usableBy)
         {
            color = TooltipHelper.BETTER_COLOR;
         }
         this.attributes += "MP Cost: " + TooltipHelper.wrapInFontTag(String(finalCost),color);
         if(multChange != 0)
         {
            this.attributes += TooltipHelper.wrapInFontTag(" (" + WithSign(multChange) + ")",TooltipHelper.getTextColor(-multChange));
         }
         var essChange:int = this.itemData.EssenceUpgrades.MpCost;
         if(essChange != 0)
         {
            awakenedColor = MoreColorUtil.toHtmlString(TooltipHelper.AWAKENED_COLOR);
            this.attributes += TooltipHelper.wrapInFontTag(" (" + WithSign(essChange) + ")",awakenedColor);
         }
         if(reforgeInc != 0)
         {
            this.attributes += TooltipHelper.wrapInFontTag(" (" + this.itemData.getChangeText(reforgeInc) + ")",this.itemData.getColorFromTier());
         }
         this.attributes += "\n";
      }
      
      private function makeItemMpDrainCost() : void
      {
         var cost2:int = 0;
         if(!this.itemData.Usable)
         {
            return;
         }
         var cost:int = this.itemData.MpDrainCost;
         var color:String = TooltipHelper.NO_DIFF_COLOR;
         if(Boolean(this.equipData) && this.equipData.MpDrainCost > 0)
         {
            cost2 = this.equipData.MpDrainCost;
            color = TooltipHelper.getTextColor(cost2 - cost);
         }
         else if(this.usableBy)
         {
            color = TooltipHelper.BETTER_COLOR;
         }
         this.attributes += "MP Drain: " + TooltipHelper.wrapInFontTag(String(cost),color) + "\n";
      }
      
      private function makeItemHpCost() : void
      {
         var cost2:int = 0;
         if(!this.itemData.Usable)
         {
            return;
         }
         var cost:int = this.itemData.HpCost;
         var color:String = TooltipHelper.NO_DIFF_COLOR;
         if(Boolean(this.equipData) && this.equipData.HpCost > 0)
         {
            cost2 = this.equipData.HpCost;
            color = TooltipHelper.getTextColor(cost2 - cost);
         }
         else if(this.usableBy)
         {
            color = TooltipHelper.BETTER_COLOR;
         }
         this.attributes += "HP Cost: " + TooltipHelper.wrapInFontTag(String(cost),color) + "\n";
      }
      
      private function makeItemHpDrainCost() : void
      {
         var cost2:int = 0;
         if(!this.itemData.Usable)
         {
            return;
         }
         var cost:int = this.itemData.HpDrainCost;
         var color:String = TooltipHelper.NO_DIFF_COLOR;
         if(Boolean(this.equipData) && this.equipData.HpDrainCost > 0)
         {
            cost2 = this.equipData.HpDrainCost;
            color = TooltipHelper.getTextColor(cost2 - cost);
         }
         else if(this.usableBy)
         {
            color = TooltipHelper.BETTER_COLOR;
         }
         this.attributes += "HP Drain: " + TooltipHelper.wrapInFontTag(String(cost),color);
         if(this.itemData.AlternativeHpDrainCost != -1)
         {
            this.attributes += " -> " + TooltipHelper.wrapInFontTag(String(this.itemData.AlternativeHpDrainCost),color);
         }
         this.attributes += "\n";
      }
      
      private function makeItemMpEndCost() : void
      {
         var cost2:int = 0;
         var mpReduction:int = 0;
         if(!this.itemData.Usable)
         {
            return;
         }
         var mpMult:int = Boolean(this.player) ? this.player.mpMult : 100;
         var reducedCost:int = this.itemData.MpEndCost * (mpMult / 100);
         var cost:int = this.itemData.MpEndCost;
         var color:String = TooltipHelper.NO_DIFF_COLOR;
         if(Boolean(this.equipData) && this.equipData.MpEndCost > 0)
         {
            cost2 = this.equipData.MpEndCost;
            color = TooltipHelper.getTextColor(cost2 - cost);
         }
         else if(this.usableBy)
         {
            color = TooltipHelper.BETTER_COLOR;
         }
         this.attributes += "MP Cost: " + TooltipHelper.wrapInFontTag(String(reducedCost),color);
         if(reducedCost != this.itemData.MpEndCost)
         {
            mpReduction = this.itemData.MpEndCost - reducedCost;
            this.attributes += TooltipHelper.wrapInFontTag(" (-" + String(mpReduction) + ")",TooltipHelper.BETTER_COLOR);
         }
         this.attributes += "\n";
      }
      
      private function makeItemCooldown() : void
      {
         var cd2:Number = NaN;
         var awakenedColor:String = null;
         var cd:Number = this.itemData.Cooldown;
         var color:String = TooltipHelper.NO_DIFF_COLOR;
         if(Boolean(this.equipData) && this.equipData.Usable)
         {
            cd2 = this.equipData.Cooldown;
            color = TooltipHelper.getTextColor(cd2 - cd);
         }
         else if(this.usableBy)
         {
            color = TooltipHelper.BETTER_COLOR;
         }
         this.attributes += "Cooldown: " + TooltipHelper.wrapInFontTag(cd + " secs",color);
         var essChange:int = this.itemData.EssenceUpgrades.Cooldown;
         if(essChange != 0)
         {
            awakenedColor = MoreColorUtil.toHtmlString(TooltipHelper.AWAKENED_COLOR);
            this.attributes += TooltipHelper.wrapInFontTag(" (" + WithSign(essChange) + ")",awakenedColor);
         }
         this.attributes += "\n";
      }
      
      private function makeHunterItemInfo() : void
      {
         var cost:int = this.itemData.UpgradeCost;
         var req:int = this.itemData.UpgradeRequirement;
         var color:String = TooltipHelper.NO_DIFF_COLOR;
         if(Boolean(this.player))
         {
            if(this.player.souls >= cost)
            {
               color = TooltipHelper.BETTER_COLOR;
            }
            else
            {
               color = TooltipHelper.WORSE_COLOR;
            }
         }
         if(this.itemData.HunterLevel < 4)
         {
            this.attributes += "Upgrade Price: " + TooltipHelper.wrapInFontTag(String(cost),color) + " Soul Points" + "\n";
         }
         if(this.itemData.HunterLevel != 0)
         {
            this.makeHarvestedSouls(req);
         }
      }
      
      private function makeHarvestedSouls(req:int) : void
      {
         var harvested:int = this.itemData.HarvestedSouls;
         var color:String = TooltipHelper.WORSE_COLOR;
         if(req > 0)
         {
            if(harvested >= req)
            {
               color = TooltipHelper.BETTER_COLOR;
            }
         }
         else
         {
            color = TooltipHelper.NO_DIFF_COLOR;
         }
         var harvStr:String = req > 0 ? "/" + req : "";
         this.attributes += "Harvested Souls: " + TooltipHelper.wrapInFontTag(harvested + harvStr,color) + "\n";
      }
      
      private function makeBoosterDesc() : void
      {
         var dur:int = this.itemData.Durability;
         this.attributes += "Durability: " + TooltipHelper.wrapInFontTag(dur + "/7",TooltipHelper.getTextColor(dur - 3)) + "\n";
         var chance:Number = this.getBreakChance();
         this.attributes += "Chance of Breaking: " + TooltipHelper.wrapInFontTag(chance + "%",TooltipHelper.getTextColor(30 - chance)) + "\n";
      }
      
      private function makeEpicKeyDesc() : void
      {
         this.attributes += "<b>" + TooltipHelper.wrapInFontTag("This key leads to an epic version of this dungeon","#FFD700") + "</b>\n";
      }
      
      private function getBreakChance() : int
      {
         return MathUtil2.roundTo(100 - (this.itemData.Durability / 7 - 0.05) * 100,2);
      }
      
      private function drawAttributes() : void
      {
         if(this.attributes.length <= 0)
         {
            return;
         }
         if(!this.line1)
         {
            this.drawLine1();
         }
         var sheet:StyleSheet = new StyleSheet();
         sheet.parseCSS(CSS_TEXT);
         this.attributesText = new SimpleText(14,11776947,false,WIDTH - 10);
         this.attributesText.styleSheet = sheet;
         this.attributesText.wordWrap = true;
         this.attributesText.htmlText = this.attributes;
         this.attributesText.useTextDimensions();
         if(Boolean(Parameters.data.toolTipOutline))
         {
            this.attributesText.filters = FilterUtil.getTextOutlineFilter();
         }
         else
         {
            this.attributesText.filters = FilterUtil.getTextShadowFilter();
         }
         if(!this.informationText)
         {
            this.attributesText.x = this.descText.x;
            this.attributesText.y = this.line1.y + this.line1.height + 3;
         }
         else
         {
            this.attributesText.x = this.descText.x;
            this.attributesText.y = this.informationText.y + this.informationText.height - 3;
         }
         this.addToolTip(this.attributesText);
      }
      
      private function drawLine1() : void
      {
         var color:uint = this.usableBy ? 8553090 : 10965039;
         this.line1 = new Sprite();
         this.line1.x = 2;
         this.line1.y = this.descText.y + this.descText.height + 4;
         this.line1.graphics.lineStyle(2,color);
         this.line1.graphics.lineTo(WIDTH - 2,0);
         this.line1.graphics.lineStyle();
         this.addToolTip(this.line1);
      }
      
      private function makeSpecifications() : void
      {
         var awakenedColor:String = null;
         this.specifications = "";
         if(this.itemData.Resurrects)
         {
            this.specifications += textColor("This item resurrects you from death, but shatters your character, making it unable to be resurrected again and making all your items soulbound.\n","#58C5FF");
         }
         if(this.itemData.LimitedUses > 0)
         {
            this.specifications += "You have " + noDiffColor(this.itemData.UsesLeft + "/" + this.itemData.LimitedUses) + " uses left\n";
         }
         if(this.itemData.CraftingMaterial)
         {
            if(this.container is MaterialSlot)
            {
               this.specifications += "Click to take out of the satchel\n";
            }
            else if(Boolean(this.player) && this.player.hasSatchel_)
            {
               this.specifications += "Double-Click to store in the satchel\n";
            }
            else
            {
               this.specifications += "This item can be stored in the Materials Satchel\n";
            }
         }
         if(this.itemData.HunterLevel > 0)
         {
            this.makeTabletSlots();
         }
         if(this.itemData.Awakened && !this.itemData.NoEssences)
         {
            awakenedColor = MoreColorUtil.toHtmlString(TooltipHelper.AWAKENED_COLOR);
            this.specifications += TooltipHelper.wrapInFontTag("Essence Upgrades: {0}/{1}\n".replace("{0}",this.itemData.Essences).replace("{1}",this.itemData.MaxEssences),awakenedColor);
            this.specifications += "Each Essence Grants: {0}\n".replace("{0}",this.itemData.EssenceUpgrades.GetUpgradesString());
         }
         if(this.itemData.VaultItem)
         {
            this.specifications += TooltipHelper.wrapInFontTag("<b>Store this item in your Vault</b>\n",TooltipHelper.NO_DIFF_COLOR);
         }
         if(this.itemData.AdminGiven)
         {
            this.specifications += TooltipHelper.wrapInFontTag("Given by an Admin\n",TooltipHelper.SPECIAL_COLOR);
         }
         if(this.itemData.Soulbound)
         {
            this.specifications += TooltipHelper.wrapInFontTag("Soulbound\n",TooltipHelper.SPECIAL_COLOR);
         }
         if(this.itemData.NotMarketable)
         {
            this.specifications += "Cannot be listed on market\n";
         }
         if(this.container is ItemGrid && !(this.container is ContainerGrid))
         {
            if(this.itemData.FusionInteraction && !(this.itemData.Consumable || this.itemData.Reusable))
            {
               this.specifications += "Shift + Right-Click to toggle quick fusing\n";
            }
         }
         this.makeUsableBy();
         if(this.itemData.Usable)
         {
            this.specifications += TooltipHelper.wrapInFontTag("Press [" + KeyCodes.CharCodeStrings[Parameters.data.useSpecial] + "] in world to use\n","#DEDAEB");
         }
         if(ItemConstants.isEquippable(this.itemData.SlotType))
         {
            this.specifications += "Must be equipped to use\n";
         }
         if(this.itemData.Consumable)
         {
            this.specifications += "Double-Click to consume\n";
            if(this.itemData.MaxDoses > 1)
            {
               this.specifications += "Shift + Right-Click to consume stack\n";
            }
         }
         if(this.itemData.Reusable)
         {
            this.specifications += "Double-Click to use\n";
            if(this.itemData.LimitedUses <= 0)
            {
               this.specifications += "This item has unlimited uses\n";
            }
         }
      }
      
      private function makeTabletSlots() : void
      {
         this.specifications += TooltipHelper.wrapInFontTag("[ <b>" + this.itemData.TabletSlots + "</b> " + TooltipHelper.getPluralText(this.itemData.TabletSlots,"tablet slot") + " ]\n","#DEDAEB");
      }
      
      private function makeUsableBy() : void
      {
         if(!ItemConstants.isEquippable(this.itemData.SlotType))
         {
            return;
         }
         if(!this.usableBy)
         {
            this.specifications += "<b>" + TooltipHelper.wrapInFontTag("Not usable by " + ObjectLibrary.typeToDisplayId_[this.player.objectType_],"#FC8642") + "</b>\n";
         }
         var usableBy:Vector.<String> = ObjectLibrary.usableBy(this.itemData.ObjectType);
         if(Boolean(usableBy) && Boolean(this.player))
         {
            this.specifications += "Usable by: " + usableBy.join(", ") + "\n";
         }
      }
      
      private function makeItemEffects() : void
      {
         var eff:int = 0;
         this.itemEffects = "";
         if(!this.itemData.ItemEffects || this.itemData.ItemEffects.length < 1)
         {
            return;
         }
         this.itemEffects += "<span class=\"ieIn\">";
         for each(eff in this.itemData.ItemEffects)
         {
            this.itemEffects += TooltipHelper.wrapInFontTag(this.GetEffectText(eff),GetEffectColor(eff));
            if(!LastElement(eff,this.itemData.ItemEffects))
            {
               this.itemEffects += "\n";
            }
         }
         if(this.itemData.EffectsArePassive)
         {
            this.itemEffects += TooltipHelper.wrapInFontTag("\nThis item\'s effect can be activated passively while in inventory.",GetEffectColor(eff));
         }
         this.itemEffects += "</span>\n";
      }
      
      private function drawItemEffects() : void
      {
         if(this.itemEffects.length <= 0)
         {
            return;
         }
         var sheet:StyleSheet = new StyleSheet();
         sheet.parseCSS(CSS_TEXT);
         this.itemEffectsText = new SimpleText(14,11776947,false,WIDTH - 10);
         this.itemEffectsText.styleSheet = sheet;
         this.itemEffectsText.wordWrap = true;
         this.itemEffectsText.htmlText = this.itemEffects;
         this.itemEffectsText.useTextDimensions();
         if(Boolean(Parameters.data.toolTipOutline))
         {
            this.itemEffectsText.filters = FilterUtil.getTextOutlineFilter();
         }
         else
         {
            this.itemEffectsText.filters = FilterUtil.getTextShadowFilter();
         }
         if(this.line2 == null)
         {
            this.drawLine2();
         }
         this.itemEffectsText.x = this.descText.x;
         this.itemEffectsText.y = this.specificationsText == null ? this.line2.y + this.line2.height + 3 : this.specificationsText.y + this.specificationsText.height - 3;
         this.addToolTip(this.itemEffectsText);
      }
      
      private function drawSpecifications() : void
      {
         if(this.specifications.length <= 0)
         {
            return;
         }
         this.drawLine2();
         var sheet:StyleSheet = new StyleSheet();
         sheet.parseCSS(CSS_TEXT);
         this.specificationsText = new SimpleText(14,11776947,false,WIDTH - 10);
         this.specificationsText.styleSheet = sheet;
         this.specificationsText.wordWrap = true;
         this.specificationsText.htmlText = this.specifications;
         this.specificationsText.useTextDimensions();
         if(Boolean(Parameters.data.toolTipOutline))
         {
            this.specificationsText.filters = FilterUtil.getTextOutlineFilter();
         }
         else
         {
            this.specificationsText.filters = FilterUtil.getTextShadowFilter();
         }
         this.specificationsText.x = this.descText.x;
         this.specificationsText.y = this.line2.y + this.line2.height + 3;
         this.addToolTip(this.specificationsText);
      }
      
      private function drawLine2() : void
      {
         var color:uint = this.usableBy ? 8553090 : 10965039;
         this.line2 = new Sprite();
         this.line2.x = 2;
         if(Boolean(this.attributesText))
         {
            this.line2.y = this.attributesText.y + this.attributesText.height + 4;
         }
         else if(Boolean(this.informationText))
         {
            this.line2.y = this.informationText.y + this.informationText.height + 4;
         }
         else
         {
            this.line2.y = this.descText.y + this.descText.height + 4;
         }
         this.line2.graphics.lineStyle(2,color);
         this.line2.graphics.lineTo(WIDTH - 2,0);
         this.line2.graphics.lineStyle();
         this.addToolTip(this.line2);
      }
      
      private function addMask() : void
      {
         var mask:Sprite = new Sprite();
         mask.graphics.beginFill(this.backColor,1);
         mask.graphics.drawRect(0,0,this.width,this.height);
         mask.graphics.endFill();
         this.equipContainer.addChild(mask);
         this.equipContainer.mask = mask;
      }
      
      private function drawFloorLine() : void
      {
         var line:Sprite = new Sprite();
         line.graphics.beginFill(0,0);
         line.graphics.drawRect(0,0,this.width,0);
         line.graphics.endFill();
         line.y = this.height;
         this.floorLine = line;
         this.addToolTip(line);
      }
      
      private function addScrollHelper() : void
      {
         this.scrollingHelper = new Sprite();
         var helperText:SimpleText = new SimpleText(14,16777215);
         helperText.text = "Ctrl + Mouse Wheel to scroll down";
         helperText.setBold(true).updateMetrics();
         helperText.x = -helperText.width / 2;
         helperText.filters = [new DropShadowFilter(0,0,0,1,12,12,3,3)];
         this.scrollingHelper.addChild(helperText);
         addChild(this.scrollingHelper);
         this.scrollingHelper.x = WIDTH / 2;
         this.scrollingHelper.y = y + HEIGHT - 15;
      }
      
      private function scrollHelperFadeOut() : void
      {
         if(this.scrollingHelper == null)
         {
            return;
         }
         removeChild(this.scrollingHelper);
         this.scrollingHelper = null;
      }
      
      private function animateTexture(e:TimerEvent) : void
      {
         var textureFile:String = this.frames[this.currFrame].File;
         if(textureFile == null)
         {
            return;
         }
         var texture:BitmapData = AssetLibrary.getImageFromSet(textureFile,this.frames[this.currFrame].Index);
         texture = TextureRedrawer.redraw(texture,70,true,0,false,5);
         this.icon.bitmapData = texture;
         this.icon.x = this.icon.y = -4;
         ++this.currFrame;
         if(this.currFrame >= this.frames.length)
         {
            this.currFrame = 0;
         }
      }
      
      private function getMarkOfTheHuntressCooldown() : Number
      {
         if(this.player == null)
         {
            return 0.75;
         }
         var ability:ItemData = this.player.equipment_[1];
         if(ability == null)
         {
            return 0.75;
         }
         return 0.75 + ability.MpCost / 20 * 0.25;
      }
   }
}

