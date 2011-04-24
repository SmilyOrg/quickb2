package QuickB2.stock 
{
	import As3Math.general.*;
	import flash.display.*;
	import flash.utils.*;
	import QuickB2.debugging.*;
	import QuickB2.events.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	import SoundTree.objects.*;
	
	public class qb2SoundEmitter extends qb2Body
	{
		public var ignoreList:Array = null;
		
		public function qb2SoundEmitter()
		{
			addEventListener(qb2ContainerEvent.ADDED_TO_WORLD, addedOrRemoved, null, true);
			addEventListener(qb2ContainerEvent.REMOVED_FROM_WORLD, addedOrRemoved, null, true);
			addEventListener(qb2ContactEvent.CONTACT_STARTED, contact, null, true);
			addEventListener(qb2ContactEvent.CONTACT_ENDED, contact, null, true);
			addEventListener(qb2MassEvent.MASS_PROPS_CHANGED, massOrAreaChanged, null, true);
		}
		
		private function addedOrRemoved(evt:qb2ContainerEvent):void
		{
			if ( evt.type == qb2ContainerEvent.ADDED_TO_WORLD )
			{
				globalSoundFieldList.unshift(evt.child);
			}
			else
			{
				globalSoundFieldList.splice(globalSoundFieldList.indexOf(this), 1);
			}
		}
		
		public static var ear:qb2Tangible = null;
		
		private static var globalSoundFieldList:Vector.<qb2SoundEmitter> = new Vector.<qb2SoundEmitter>();
		private static var soundDict:Dictionary = new Dictionary(true);
		
		public function get sound():stSoundObject
			{  return _sound;  }
		public function set sound(object:stSoundObject):void
		{
			if ( _sound )
			{
				var array:Vector.<qb2SoundEmitter> = soundDict[_sound];
				array.splice(array.indexOf(this), 1);
				if ( !array.length )
				{
					delete soundDict[_sound];
					_sound.stop();
				}
			}
			
			_sound = object;
			
			if ( _sound )
			{
				if ( !soundDict[_sound] )
				{
					array = new Vector.<qb2SoundEmitter>();
					array.push(this);
					soundDict[_sound] = array;
				}
			}
		}
		private var _sound:stSoundObject;
		
		protected override function update():void
		{
			super.update();
	
			//--- We can only update sound volumes when the last sound field is updated.
			if ( this == globalSoundFieldList[globalSoundFieldList.length - 1] )
			{
				updateVolumes();
			}
		}
		
		private static function updateVolumes():void
		{
			var soundVolumeDict:Dictionary = new Dictionary(true);
			var soundCountDict:Dictionary = new Dictionary(true);
			
			for (var i:int = 0; i < globalSoundFieldList.length; i++) 
			{
				var soundField:qb2SoundEmitter = globalSoundFieldList[i];
				
				if ( !soundField._sound )  continue;
				
				var continueToNext:Boolean = false;
				var ignores:Array = soundField.ignoreList;
				for (var j:int = 0; j < ignores.length; j++) 
				{
					var ignore:* = ignores[j];
					
					if ( ignore is Class )
					{
						var asClass:Class = ignore as Class;
						if ( ear is asClass )
						{
							continueToNext = true;
						}
					}
					else if ( ignore == ear )
					{
						continueToNext = true;
					}
				}
				
				if ( continueToNext )  continue;

				var soundEmitter_inContactWithEar:Boolean = false;
				for (var key:* in soundField.shapeContactList ) 
				{
					var shape:qb2Shape = key as qb2Shape;
					
					if ( shape == ear )
					{
						soundEmitter_inContactWithEar = true;
						break;
					}
					else if ( ear is qb2ObjectContainer )
					{
						if ( shape.isDescendantOf(ear as qb2ObjectContainer) )
						{
							soundEmitter_inContactWithEar = true;
							break;
						}
					}
				}
				
				if ( !soundEmitter_inContactWithEar )
				{
					continue;
				}
				
				var volume:Number = 1;
				
				if ( soundField._horizonTang )
				{
					var distance:Number = soundField.distanceTo(ear, null, null, null, soundField._horizonTang);
					volume = 1-amUtils.constrain(distance / soundField._horizon, 0, 1);
				}
				
				if ( !soundVolumeDict[soundField._sound] )
				{
					soundVolumeDict[soundField._sound] = 0.0 as Number;
					soundCountDict[soundField._sound] = 0 as int;
				}
				
				soundVolumeDict[soundField._sound] += volume;
				soundCountDict[soundField._sound]++;
			}
			
			for ( key in soundDict )
			{
				var sound:stSoundObject = key as stSoundObject;
				
				if ( soundCountDict[sound] )
				{
					var numberOfSounds:Number = soundCountDict[key];
					var soundVolume:Number = soundVolumeDict[key];
					
					sound.volume = numberOfSounds ? soundVolume / numberOfSounds : 0;
					
					if ( !sound.playing )
					{
						sound.play();
					}
				}
				else
				{
					if ( sound.playing )
					{
						sound.stop();
					}
				}
			}
		}
		
		private function contact(evt:qb2ContactEvent):void
		{
			var otherShape:qb2Shape = evt.otherShape;
			
			if ( evt.type == qb2ContactEvent.CONTACT_STARTED )
			{
				if ( !shapeContactList[otherShape] )
				{
					shapeContactList[otherShape] = 0 as int;
				}
				
				shapeContactList[otherShape]++;
			}
			else
			{
				shapeContactList[otherShape]--;
				
				if ( shapeContactList[otherShape] == 0 ) 
				{
					delete shapeContactList[otherShape];
				}
			}
		}
		private var shapeContactList:Dictionary = new Dictionary(true);
		
		public function get horizon():Number
			{  return _horizon;  }
		public function set horizon(value:Number):void
		{
			_horizon = value;
			
			refreshHorizonTang();
		}
		private var _horizon:Number = 0;
		
		private function massOrAreaChanged(evt:qb2MassEvent):void
		{
			refreshHorizonTang();
		}
		
		private function refreshHorizonTang():void
		{
			if ( _horizonTang )
			{
				removeObject(_horizonTang);
				_horizonTang = null;
			}
			
			if ( _horizon > 0 )
			{
				_horizonTang = makeHorizonTang();
				addObject(_horizonTang);
			}
		}
		private var _horizonTang:qb2Tangible = null;
		
		protected function makeHorizonTang():qb2Tangible
		{
			return null;
		}
		
		public override function drawDebug(graphics:srGraphics2d):void
		{
			pushDebugFillColor(qb2_debugDrawSettings.soundEmitterFillColor);
				super.drawDebug(graphics);
			popDebugFillColor();
			
			if ( _horizonTang )
			{
				
			}
		}
		
		public override function cloneShallow():qb2Object
		{
			var clone:qb2SoundEmitter = super.cloneShallow() as qb2SoundEmitter;
			
			clone._horizon = this._horizon; // don't use setter, cause horizonTang gets made through the clone.
			clone.sound = this.sound;
			
			if ( !ignoreList )  return clone;
			
			clone.ignoreList = [];
			
			for (var i:int = 0; i < ignoreList.length; i++) 
			{
				clone.ignoreList.push(ignoreList[i]);
			}
			
			return clone;
		}
	}
}