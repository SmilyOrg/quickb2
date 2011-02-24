package QuickB2.debugging 
{
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2DebugTraceUtils
	{
		/// Creates a string useful for trace()ing with custom variables of your choice.
		public static function formatToStringWithCustomVars(object:Object, ... varNames):String
		{
			var className:String = getClassName(object);
			return makeCompleteString(object, className, varNames);
		}
		
		/// Creates a string useful for trace()ing.  Variables for QuickB2 classes are displayed as defined in classToVariableMap.
		public static function formatToString(object:Object, baseClass:String):String
		{
			var className:String = getClassName(object);
			return makeCompleteString(object, className, qb2_debugTraceSettings.classToVariableMap[baseClass]);
		}

		private static function getClassName(object:Object):String
		{
			var className:String = object.constructor.toString();
			className = className.substring(7, className.length - 1); // strips the [class *] stuff off, leaving just the class name.
			return className;
		}
		
		private static function makeCompleteString(object:Object, className:String, varNames:Array):String
		{
			var toReturn:String = qb2_debugTraceSettings.classEnclosures.charAt(0) + className + qb2_debugTraceSettings.varEnclosures.charAt(0);
			
			var varDelimiter:String = qb2_debugTraceSettings.varDelimiter;
			if ( varNames )
			{
				for (var i:int = 0; i < varNames.length; i++)
				{
					var varName:String = varNames[i] as String;
				
					if ( !varName )  continue;
					
					var variable:Object = object[varName];
					toReturn += varName + qb2_debugTraceSettings.equalityCharacter + variable;
					
					if ( i < varNames.length - 1 )
					{
						toReturn += varDelimiter;
					}
				}
			}
			else
			{
				toReturn += "no variables provided";
			}
			
			toReturn += qb2_debugTraceSettings.varEnclosures.charAt(1) + qb2_debugTraceSettings.classEnclosures.charAt(1);
			
			return toReturn;
		}
	}
}