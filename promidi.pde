/*
 Part of the proMIDI lib - http://texone.org/promidi

 Copyright (c) 2005 Christian Riekoff

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General
 Public License along with this library; if not, write to the
 Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 Boston, MA  02111-1307  USA
 */

package promidi;

import javax.sound.midi.ShortMessage;

/**
 * Controller represents a midi controller. It has a number and a value. You can
 * receive Controller values from midi ins and send them to midi outs.
 * @nosuperclasses
 * @example promidi_midiout
 * @related MidiIO
 * @related Note
 * @related ProgramChange
 */
public class Controller extends MidiEvent{

	/**
	 * Inititalizes a new Controller object.
	 * @param i_number int: number of a controller
	 * @param i_value  int: value of a controller
	 */
	public Controller(final int i_number, final int i_value){
		super(CONTROL_CHANGE, i_number, i_value);
	}
	
	/**
	 * Initialises a new Note from a java ShortMessage
	 * @param shortMessage
	 * @invisible
	 */
	Controller(ShortMessage shortMessage){
		super(shortMessage);
	}

	/**
	 * Use this method to get the number of a controller.
	 * @return int: the number of a note
	 * @example promidi
	 * @related Controller
	 * @related setNumber ( )
	 * @related getValue ( )
	 * @related setValue ( )
	 */
	public int getNumber(){
		return getData1();
	}

	/**
	 * Use this method to set the number of a controller.
	 * @return int: the number of a note
	 * @example promidi
	 * @related Controller
	 * @related getNumber ( )
	 * @related getValue ( )
	 * @related setValue ( )
	 */
	public void setNumber(final int i_number){
		setData1(i_number);
	}

	/**
	 * Use this method to get the value of a controller.
	 * @return int: the value of a note
	 * @example promidi
	 * @related Controller
	 * @related setValue ( )
	 * @related getNumber ( )
	 * @related setNumber ( )
	 */
	public int getValue(){
		return getData2();
	}

	/**
	 * Use this method to set the value of a controller.
	 * @return int, the value of a note
	 * @example promidi
	 * @related Controller
	 * @related getValue ( )
	 * @related setValue ( )
	 * @related getNumber ( )
	 */
	public void setValue(final int i_value){
		setData2(i_value);
	}
}
/*
Part of the proMIDI lib - http://texone.org/promidi

Copyright (c) 2005 Christian Riekoff

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General
Public License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA  02111-1307  USA
*/

/**
 * Must be in the javax.sound.midi package because the constructor is package-private
 */
package promidi;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;
import java.util.SortedMap;
import java.util.TreeMap;
import java.util.Vector;

import javax.sound.midi.ShortMessage;

/**
 * A track handles all midiEvents of a song for a certain midiout. You can directly 
 * add Events like Notes or ControllerChanges to it or also work with patterns.
 */
public class Pattern{

	/**
	 * Holds the MidiEvents of the track ordered to their ticks
	 */
	private TickMapEvents tickMapEvents = new TickMapEvents();

	Vector controllerStateMessages;

	/**
	 * A map with the controller data
	 */
	private HashMap controllerMap = new HashMap();

	/**
	 * use a hashset to detect duplicate events in add(MidiEvent)
	 */
	private HashSet set = new HashSet();
	
	/**
	 * To store the playing notes
	 */
	private NoteOnCache noteOnCache = new NoteOnCache();

	/**
	 * The name of the track
	 */
	private String name;
	
	/**
	 * Song the track is added to
	 */
	private Song song;
	
	/**
	 * Length of the pattern in ticks
	 */
	private long length;
	
	/**
	 * Creates a new pattern with the given name and length
	 * @param i_name String: the name of the pattern
	 * @param i_length long: the length of the pattern in ticks
	 */
	public Pattern(
		final String i_name, 
		final long i_length
	){
		name = i_name;
		length = i_length;
		controllerStateMessages = new Vector();
		controllerStateMessages.ensureCapacity(128);
	}
	
	/////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////
	//
	// MANAGING PATTERNS
	//
	/////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////
	
	private static class Key{
		long startTick;
		long endTick;
		
		Key(
			final long i_startTick,
			final long i_endTick
		){
			startTick = i_startTick;
			endTick = i_endTick;
		}
		
		boolean tickIsInRange(final long i_tick){
			return i_tick >= startTick && i_tick <= endTick;
		}
	}
	/**
	 * the patterns of the map
	 */
	private Pattern[] patterns = new Pattern[0];
	
	private Key[] keys = new Key[0];
	
	
	private int patternSize = 0;
	
	/**
    * Increases the capacity of the arrays for the patterns and keys instance, if
    * necessary, to ensure  that it can hold at least the number of elements
    * specified by the minimum capacity argument. 
    *
    * @param   minCapacity   the desired minimum capacity.
    */
   private void ensureCapacity(final int minCapacity) {
   	int oldCapacity = patterns.length;
   	
   	if (minCapacity > oldCapacity) {
   		Pattern oldPattern[] = patterns;
   		Key oldKeys[] = keys;
	    
   		int newCapacity = (oldCapacity * 3)/2 + 1;
   	    
   		if (newCapacity < minCapacity)newCapacity = minCapacity;
	    
   		patterns = new Pattern[newCapacity];
   		keys = new Key[newCapacity];
   		System.arraycopy(oldPattern, 0, patterns, 0, patternSize);
   		System.arraycopy(oldKeys, 0, keys, 0, patternSize);
   	}
   }
   
   /**
    * Checks and sets the length value for example after removing
    * or adding an event.
    *
    */
   private void checkLength(){
   	length = tickMapEvents.getMaxTick();
		
		for(int i = 0; i < keys.length; i++){
			length = Math.max(length,keys[i].endTick);
		}
   }
   
   /**
    * quantization of the pattern
    */
   private int quantization = Q.NONE;
   
   /**
    * One bar of pattern is subdevided into 512 ticks. You can set a 
    * quantization for simplified input of events. If you set the 
    * quantization to _1_4 you can add quarter notes with the values
    * 0,1,2,3 instead of 0,128,256,384.
    * @shortdesc Sets the quantization for a pattern.
    * @param i_quantization Either: _1_2,_1_4,_1_8,_1_16,_1_32,_1_64
    * @related Quantization
    * @related getQuantization ( )
    * @related addEvent ( )
    */
   public void setQuantization(final int i_quantization){
   	quantization = i_quantization;
   }
   
   /**
    * Returns the current quantization of the pattern.
    * @return int: actual quantization o the pattern
    * @related setQuantization ( )
    */
   public int getQuantization(){
   	return quantization;
   }

	
	/**
	 * Use this method to add a pattern to this pattern. A pattern builds
	 * a sequence of events that you can place several times into several tracks.
	 * Putting patterns into patterns can be used create complex strucures.
	 * Note that if you have set a quantization
	 * @param i_pattern Pattern: the pattern to be added to the track
	 * @param i_long long: the position in ticks where the pattern should be placed
	 * @shortdesc Use this method to add a pattern to the track.
	 * @related Pattern
	 * @related removePattern ( )
	 * @related setQuantization ( )
	 */
	public void addPattern(
		final Pattern i_pattern, 
		final long i_tick
	){	
		addPattern(i_pattern,i_tick,quantization);
	}
	
	/**
	 * @param i_quantization the quantization
	 */
	public void addPattern(
		final Pattern i_pattern, 
		final long i_tick,
		final int i_quantization
	){	
		final long startTick = i_quantization*i_tick;
		final long endTick = startTick + i_pattern.ticks();
		final Key key = new Key(startTick,endTick);
		length = Math.max(length,endTick);
		ensureCapacity(patternSize + 1);  // Increments modCount!!
		patterns[patternSize] = i_pattern;
		keys[patternSize] = key;
		patternSize++;
	}
	
	/**
	 * Use this method to remove a pattern from a track. A pattern builds
	 * a sequence of events that you can place several times into several tracks.
	 * Removing a pattern removes all its events from the track. Calling the method
	 * including a tick value only deletes patterns for this tick.
	 * @param i_pattern Pattern: the pattern to be removed from the pattern
	 * @param i_tick long: position of the Pattern
	 * @shortdesc Use this method to add a pattern to the track.
	 * @related Pattern
	 * @related addPattern ( )
	 */
	public void removePattern(
		final Pattern i_pattern, 
		final long i_tick
	){
		for(int i = 0; i < patternSize; i++){
			if(patterns[i].equals(i_pattern) && (keys[i].startTick == i_tick || i_tick == -1)){

				int numMoved = patterns.length - i - 1;
				if (numMoved > 0){
				    System.arraycopy(patterns, i+1, patterns, i, numMoved);
				    System.arraycopy(keys, i+1, keys, i, numMoved);
				}
				//	Let gc do its work
				patternSize--;
				patterns[patternSize] = null; 
				keys[patternSize] = null;
			}
		}
		
		checkLength();
	}
	
	/**
	 * 
	 * @param i_pattern Pattern: the pattern to be removed from the pattern
	 */
	public void removePattern(final Pattern i_pattern){
		removePattern(i_pattern,-1);
	}
	
	/////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////
	//
	// MANAGING EVENTS
	//
	/////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////

	/**
	 * Adds an Event to the TickMap so that it can be played by the sequencer.
	 * If the event contains controller data it is also added to the controller
	 * map for correct looping.
	 * @param i_event MidiEvent: to be added to the tickMap
	 */
	private void addEventToTickMap(
		final MidiEvent i_event,
		final long i_tick
	){
		length = Math.max(i_tick,length);
		tickMapEvents.addEvent(i_event,i_tick);
		addToControllerMap(i_event,i_tick);
	}

	/**
	 * Adds the incoming midi even to the controller map
	 * @param i_event MidiEvent: to be added to the controllermap
	 */
	private void addToControllerMap(
		final MidiEvent i_event,
		final long i_tick
	){
		try{
			if (i_event.getCommand() == ShortMessage.CONTROL_CHANGE){

				int ccKey = ((i_event.getChannel() & 0xf) << 8) | (i_event.getData1() & 0xff);

				SortedMap ccValues;
				ccValues = (SortedMap) controllerMap.get(new Integer(ccKey));
				if (ccValues == null){
					ccValues = new TreeMap();
					controllerMap.put(new Integer(ccKey), ccValues);
				}

				ccValues.put(new Long(i_tick), new Integer(i_event.getData2()));
			}
		}catch (Exception e){
			// e.printStackTrace();
		}
	}

	/**
	 * Removes the given MidiEvent from the controller map
	 * @param i_event
	 */
	private void removeFromControllerMap(
		final MidiEvent i_event,
		final long i_tick
	){
		try{
			if (i_event.getCommand() == ShortMessage.CONTROL_CHANGE){
				int ccKey = ((i_event.getChannel() & 0xf) << 8) | (i_event.getData1() & 0xff);
				((SortedMap) controllerMap.get(new Integer(ccKey))).remove(new Long(i_tick));
			}
		}catch (Exception e){
		}
	}
	
	/**
	 * Used by the sequencer to play the events for the given tick.
	 * @param tick ,thats MidiEvents has to be returned
	 */
	void sendEventsForTick(
		final long i_tick,
		final MidiOut i_midiOut
	){
		final Vector eventsForTick = tickMapEvents.getEventsForTick(i_tick);
		
		if(eventsForTick!=null){
			for (int j = 0; j < eventsForTick.size(); j++){
				MidiEvent event = (MidiEvent)eventsForTick.get(j);
				i_midiOut.sendEvent(event);
			}
		}
		
		for(int i = 0; i < keys.length; i++){
			if(keys[i].tickIsInRange(i_tick)){
				patterns[i].sendEventsForTick(i_tick,i_midiOut);
			}
		}
	}

	/**
	 * Return a list of midimessages in order to restore controller states at a specific tick.
	 * Used when looping a sequence, or when starting playback in the middle of the song.
	 * @param i_tick
	 * @return
	 */
	private synchronized Vector getControllerStateAtTick(final long i_tick){

		controllerStateMessages.clear();
		Set controllerMapKeys = controllerMap.keySet();
		for (Iterator it = controllerMapKeys.iterator(); it.hasNext();){
			int ccKey = ((Integer) it.next()).intValue();
			SortedMap ccValues = (SortedMap) controllerMap.get(new Integer(ccKey));
			try{
				int ccValue = ((Integer) ccValues.get(ccValues.headMap(new Long(i_tick)).lastKey())).intValue();
				ShortMessage shm = new ShortMessage();
				shm.setMessage(ShortMessage.CONTROL_CHANGE, (ccKey >> 8) & 0xf, ccKey & 0xff, ccValue);
				controllerStateMessages.add(shm);
			}catch (Exception e){
			}
		}

		return controllerStateMessages;
	}
	
	/**
	 * Resets the midi controllers at the given tick. THis method is called 
	 * by the sequencer when looping a sequence, or when starting playback in 
	 * the middle of the song.
	 * @param i_tick
	 */
	void resetControllers(
		final long i_tick,
		final MidiOut i_midiOut
	){
		final Vector midiMessages = getControllerStateAtTick(i_tick);
		for (int j = 0; j < midiMessages.size(); j++){
			i_midiOut.sendEvent((MidiEvent) midiMessages.get(j));
		}
		
		for(int i = 0; i < keys.length; i++){
			if(keys[i].tickIsInRange(i_tick)){
				patterns[i].resetControllers(i_tick,i_midiOut);
			}
		}
	}

	/**
	 * Sends a noteOff for all actual notes.
	 */
	void flushNoteOnCache(
		final MidiOut i_midiOut
	){
		final Vector notes = noteOnCache.getPendingNoteOffs();
		for (int i = 0; i < notes.size(); i++){
			int note = ((Integer) notes.get(i)).intValue();
			i_midiOut.sendEvent(MidiEvent.NOTE_ON, (note >> 8) & 0xf, note & 0xff);
		}
		noteOnCache.releasePendingNoteOffs();
		
		for(int i = 0; i < patterns.length; i++){
				patterns[i].flushNoteOnCache(i_midiOut);
		}
	}
	
	/**
	 * Returns the song the track was added to
	 * @return
	 */
	Song getSong(){
		return song;
	}
	
	/**
	 * Set the song the track was added to
	 * @param i_song
	 */
	void setSong(final Song i_song){
		song = i_song;
	}
	
	/**
	 * Returns the name of the pattern.
	 * @return String: the name of the pattern
	 */
	public String getName(){
		return name;
	}
	
	/**
	 * Sets the name of the track.
	 * @param i_name String: the new name of track
	 */
	public void setName(final String i_name){
		name = i_name;
	}
	
	/**
	 * Adds a new event to the pattern or track.  However, if the event is already
	 * contained, it is not added again.  The list of events
	 * is kept in time order, meaning that this event inserted at the
	 * appropriate place in the list, not necessarily at the end.
	 * @shortdesc Adds a new event to the pattern or track.
	 * @example promidi_sequencer
	 * @param i_event the event to add
	 * @return <code>true</code> if the event did not already exist in the
	 * track and was added, otherwise <code>false</code>
	 */
	public boolean addEvent(
		final MidiEvent i_event,
		final long i_tick
	){
		if (i_event == null){
			return false;
		}
		
		if (!set.contains(i_event)){
			addEventToTickMap(i_event,i_tick * quantization);
			set.add(i_event);
			return true;
		}

		return false;
	}

	/**
	 * Removes the specified event from the track.
	 * @param i_event MidiEvent: the event to remove
	 * @param i_tick long: the position of the event to remove
	 * @return <code>true</code> if the event existed in the track and was removed,
	 * otherwise <code>false</code>
	 */
	public boolean removeEvent(
		final MidiEvent i_event,
		final long i_tick
	){
		if (set.remove(i_event)){
			tickMapEvents.removeEvent(i_event,i_tick);
			removeFromControllerMap(i_event,i_tick);
			length = tickMapEvents.getMaxTick();
			return true;
		}

		return false;
		
	}

	/**
	 * Obtains the number of events in this pattern.
	 * @return the size of the track's event vector
	 */
	public int size(){
		return set.size();
	}
	
   /**
	 * Obtains the length of the pattern, expressed in MIDI ticks. (The duration of
	 * a tick in seconds is determined by the timing resolution of the
	 * <code>Sequence</code> containing this track, and also by the tempo of
	 * the music as set by the sequencer.)
	 * @shortdesc Obtains the length of the pattern, expressed in MIDI ticks.
	 * @return the duration, in ticks
	 * @related Song
	 * @related Sequencer
	 */
	public long ticks(){
		return length;
	}
	
	
}
/*
Part of the proMIDI lib - http://texone.org/promidi

Copyright (c) 2005 Christian Riekoff

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General
Public License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA  02111-1307  USA
*/

package promidi;

/**
 * @invisible
 * @author tex
 *
 */
public class InvalidMidiDataException extends RuntimeException{
	static final long serialVersionUID = 0;
	InvalidMidiDataException(String message){
		super(message);
	}

}
/*
 Part of the proMIDI lib - http://texone.org/promidi

 Copyright (c) 2005 Christian Riekoff

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General
 Public License along with this library; if not, write to the
 Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 Boston, MA  02111-1307  USA
 */
package promidi;

import java.lang.reflect.Method;

/**
 * A Plug is the invocation of a method to handle incoming MidiEvents.
 * These methods are plugged by reflection, so a plug needs the name 
 * of this method and the object where it is declared.
 * @author tex
 *
 */
class Plug{

	/**
	 * The plugged method
	 */
	private final Method method;

	/**
	 * Name of the method to plug
	 */
	private final String methodName;

	/**
	 * Object containg the method to plug
	 */
	private final Object object;
	
	/**
	 * Class of the object containing the method to plug
	 */
	private final Class objectClass;
	
	/**
	 * Kind of Parameter that is handled by the plug can be
	 * NOTE, Controller, Program Change or a MidiEvent at general
	 */
	private int parameterKind;
	
	static final int MIDIEVENT = 0;
	static final int NOTE = 1;
	static final int CONTROLLER = 2;
	static final int PROGRAMCHANGE = 3;

	/**
	 * Initializes a new Plug by a method name and the object 
	 * declaring the method.
	 * @param i_object
	 * @param i_methodName
	 */
	public Plug(
		final Object i_object,
		final String i_methodName
	){
		object = i_object;
		objectClass = object.getClass();
		methodName = i_methodName;
		method = initPlug();
	}
	
	int getParameterKind(){
		return parameterKind;
	}
	
	/**
	 * @throws Exception 
	 * 
	 *
	 */
	private boolean checkParameter(final Class[] objectMethodParams) throws Exception{
		if(objectMethodParams.length == 1){
			final Class paramClass = objectMethodParams[0];
			if(paramClass.getName().equals("promidi.MidiEvent")){
				parameterKind = MIDIEVENT;
				return true;
			}else if(paramClass.getName().equals("promidi.Note")){
				parameterKind = NOTE;
				return true;
			}else if(paramClass.getName().equals("promidi.Controller")){
				parameterKind = CONTROLLER;
				return true;
			}else if(paramClass.getName().equals("promidi.ProgramChange")){
				parameterKind = PROGRAMCHANGE;
				return true;
			}
		}
		throw new Exception();
	}

	/**
	 * Intitializes the method that has been plugged.
	 * @return
	 */
	private Method initPlug(){		
		if (methodName != null && methodName.length() > 0){
			final Method[] objectMethods = objectClass.getDeclaredMethods();
			
			for (int i = 0; i < objectMethods.length; i++){
				objectMethods[i].setAccessible(true);
				
				if (objectMethods[i].getName().equals(methodName)){
					final Class[] objectMethodParams = objectMethods[i].getParameterTypes();
					try{
						checkParameter(objectMethodParams);
						return objectClass.getDeclaredMethod(methodName, objectMethodParams);
					}catch (Exception e){
						break;
					}
				}
			}
		}
		throw new RuntimeException("Error on plug: >" +methodName + 
			"< You can only plug methods that have a MidiEvent, a Note, a Controller or a ProgramChange as Parameter");
	}
	
	/**
	 * Calls the plug by invoking the method given by the plug.
	 * @param i_midiEvent
	 */
	void callPlug(final MidiEvent i_midiEvent){
       try{
			method.invoke(object,new Object[]{i_midiEvent});
		}catch (Exception e){
			e.printStackTrace();
			throw new RuntimeException("Error on calling plug: " +methodName);
		}
   }
}
/*
Part of the proMIDI lib - http://texone.org/promidi

Copyright (c) 2005 Christian Riekoff

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General
Public License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA  02111-1307  USA
*/

package promidi;

abstract class MidiDevice{

	/**
	 * the MidiDevice for this input
	 */
	final javax.sound.midi.MidiDevice midiDevice;
	
	/**
	 * the number of the midiDevice
	 */
	final int deviceNumber;

	/**
	 * Initializes a new MidiIn.
	 * @param libContext
	 * @param midiDevice
	 * @throws MidiUnavailableException
	 */
	MidiDevice(
		final javax.sound.midi.MidiDevice midiDevice, 
		final int deviceNumber
	){
		this.midiDevice = midiDevice;
		this.deviceNumber = deviceNumber;
	}
	
	String getName(){
		return midiDevice.getDeviceInfo().getName();
	}
	
	void open(){
		try{
			if(!midiDevice.isOpen()){
				midiDevice.open();
			}
			}catch (Exception e){
				throw new RuntimeException(
					"You wanted to open an unavailable output device: "+deviceNumber + " "+getName()
				);
			}
	}

	/**
	 * Closes this device
	 */
	public void close(){
		if(midiDevice.isOpen())midiDevice.close();
	}

}
/*
Part of the proMIDI lib - http://texone.org/promidi

Copyright (c) 2005 Christian Riekoff

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General
Public License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA  02111-1307  USA
*/

package promidi;

import javax.sound.midi.ShortMessage;

/**
 * ProgramChange represents a midi program change. It has a midi port, a midi channel, 
 * and a number. You can receive program changes from midi inputs and send 
 * them to midi outputs. 
 * @nosuperclasses
 * @example promidi_midiout
 * @related MidiIO
 * @related Note
 * @related Controller
 */
public class ProgramChange extends MidiEvent{
	
	/**
	 * Inititalizes a new ProgramChange object.
	 * @param midiChannel int: midi channel a program change comes from or is send to
	 * @param i_number int, number of the program change
	 */
	public ProgramChange(final int i_number){
		super(ShortMessage.PROGRAM_CHANGE,i_number,-1);
	}
	
	/**
	 * Use this method to get the program change number.
	 * @return int, the program change number
	 * @example promidi
	 */
	public int getNumber(){
		return getData1();
	}
}
/*
 Part of the proMIDI lib - http://texone.org/promidi

 Copyright (c) 2005 Christian Riekoff

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General
 Public License along with this library; if not, write to the
 Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 Boston, MA  02111-1307  USA
 */

package promidi;

import javax.sound.midi.InvalidMidiDataException;
import javax.sound.midi.MidiMessage;

/**
 * Event is the base class for all MidiEvents, like 
 * NoteOn, Controller or SysEx.
 * @invisible
 * @nosuperclasses
 */
public class MidiEvent extends MidiMessage{

	// Status byte defines

	// System common messages

	/**
	 * Status byte for MIDI Time Code Quarter Frame message (0xF1, or 241).
	 */
	static final int MIDI_TIME_CODE = 0xF1; // 241

	/**
	 * Status byte for Song Position Pointer message (0xF2, or 242).
	 */
	static final int SONG_POSITION_POINTER = 0xF2; // 242

	/**
	 * Status byte for MIDI Song Select message (0xF3, or 243).
	 */
	static final int SONG_SELECT = 0xF3; // 243

	/**
	 * Status byte for Tune Request message (0xF6, or 246).
	 */
	static final int TUNE_REQUEST = 0xF6; // 246

	/**
	 * Status byte for End of System Exclusive message (0xF7, or 247).
	 */
	static final int END_OF_EXCLUSIVE = 0xF7; // 247

	// System real-time messages

	/**
	 * Status byte for Timing Clock messagem (0xF8, or 248).
	 */
	static final int TIMING_CLOCK = 0xF8; // 248

	/**
	 * Status byte for Start message (0xFA, or 250).
	 */
	static final int START = 0xFA; // 250

	/**
	 * Status byte for Continue message (0xFB, or 251).
	 */
	static final int CONTINUE = 0xFB; // 251

	/**
	 * Status byte for Stop message (0xFC, or 252).
	 */
	static final int STOP = 0xFC; //252

	/**
	 * Status byte for Active Sensing message (0xFE, or 254).
	 */
	static final int ACTIVE_SENSING = 0xFE; // 254

	/**
	 * Status byte for System Reset message (0xFF, or 255).
	 */
	static final int SYSTEM_RESET = 0xFF; // 255

	// Channel voice message upper nibble defines

	/**
	 * Command value for Note Off message (0x80, or 128)
	 */
	static final int NOTE_OFF = 0x80; // 128

	/**
	 * Command value for Note On message (0x90, or 144)
	 */
	static final int NOTE_ON = 0x90; // 144

	/**
	 * Command value for Polyphonic Key Pressure (Aftertouch) message (0xA0, or 128)
	 */
	static final int POLY_PRESSURE = 0xA0; // 160

	/**
	 * Command value for Control Change message (0xB0, or 176)
	 */
	static final int CONTROL_CHANGE = 0xB0; // 176

	/**
	 * Command value for Program Change message (0xC0, or 192)
	 */
	static final int PROGRAM_CHANGE = 0xC0; // 192

	/**
	 * Command value for Channel Pressure (Aftertouch) message (0xD0, or 208)
	 */
	static final int CHANNEL_PRESSURE = 0xD0; // 208

	/**
	 * Command value for Pitch Bend message (0xE0, or 224)
	 */
	static final int PITCH_BEND = 0xE0; // 224

	/**
	 * field to keep the events midiPort
	 */
	private int midiChannel = 0;

	/**
	 * Constructs a new <code>ProMidiEvent</code>.
	 * @param data an array of bytes containing the complete message.
	 * The message data may be changed using the <code>setMessage</code>
	 * method.
	 * @see #setMessage
	 */
	private MidiEvent(byte[] data){
		super(data);
	}

	/**
	 * Constructs a new <code>ShortMessage</code>.  The
	 * contents of the new message are guaranteed to specify
	 * a valid MIDI message.  Subsequently, you may set the
	 * contents of the message using one of the <code>setMessage</code>
	 * methods.
	 * @see #setMessage
	 */
	private MidiEvent(){
		this(new byte[3]);
		// Default message data: NOTE_ON on Channel 0 with max volume
		data[0] = (byte) (NOTE_ON & 0xFF);
		data[1] = (byte) 64;
		data[2] = (byte) 127;
		length = 3;
	}

	MidiEvent(final MidiMessage i_midiMessage){
		this(i_midiMessage.getMessage());
	}

	/**
	 * Initializes a new Event.
	 * @param midiChannel int, midi channel of the event
	 * @param midiPort int, midi port of the  event
	 * @throws InvalidMidiDataException 
	 */
	MidiEvent(int command, int number, int value){
		this();
		try{
			setMessage(command, midiChannel, number, value);
		}catch (InvalidMidiDataException e){
			e.printStackTrace();
		}
	}

	/**
	 * Sets the parameters for a MIDI message that takes no data bytes.
	 * @param status	the MIDI status byte
	 * @throws  <code>InvalidMidiDataException</code> if <code>status</code> does not
	 * specify a valid MIDI status byte for a message that requires no data bytes.
	 * @see #setMessage(int, int, int)
	 * @see #setMessage(int, int, int, int)
	 */
	public void setMessage(int status) throws InvalidMidiDataException{
		// check for valid values
		int dataLength = getDataLength(status); // can throw InvalidMidiDataException
		if (dataLength != 0){
			throw new InvalidMidiDataException("Status byte; " + status + " requires " + dataLength + " data bytes");
		}
		setMessage(status, 0, 0);
	}

	/**
	 * Sets the  parameters for a MIDI message that takes one or two data
	 * bytes.  If the message takes only one data byte, the second data
	 * byte is ignored; if the message does not take any data bytes, both
	 * data bytes are ignored.
	 *
	 * @param status	the MIDI status byte
	 * @param data1		the first data byte
	 * @param data2		the second data byte
	 * @throws	<code>InvalidMidiDataException</code> if the
	 * the status byte, or all data bytes belonging to the message, do
	 * not specify a valid MIDI message.
	 * @see #setMessage(int, int, int, int)
	 * @see #setMessage(int)
	 */
	public void setMessage(int status, int data1, int data2) throws InvalidMidiDataException{
		// check for valid values
		int dataLength = getDataLength(status); // can throw InvalidMidiDataException
		if (dataLength > 0){
			if (data1 < 0 || data1 > 127){
				throw new InvalidMidiDataException("data1 out of range: " + data1);
			}
			if (dataLength > 1){
				if (data2 < 0 || data2 > 127){
					throw new InvalidMidiDataException("data2 out of range: " + data2);
				}
			}
		}

		// set the length
		length = dataLength + 1;
		// re-allocate array if ShortMessage(byte[]) constructor gave array with fewer elements
		if (data == null || data.length < length){
			data = new byte[3];
		}

		// set the data
		data[0] = (byte) (status & 0xFF);
		if (length > 1){
			data[1] = (byte) (data1 & 0xFF);
			if (length > 2){
				data[2] = (byte) (data2 & 0xFF);
			}
		}
	}

	/**
	 * Sets the short message parameters for a  channel message
	 * which takes up to two data bytes.  If the message only
	 * takes one data byte, the second data byte is ignored; if
	 * the message does not take any data bytes, both data bytes
	 * are ignored.
	 *
	 * @param command	the MIDI command represented by this message
	 * @param channel	the channel associated with the message
	 * @param data1		the first data byte
	 * @param data2		the second data byte
	 * @throws		<code>InvalidMidiDataException</code> if the
	 * status byte or all data bytes belonging to the message, do
	 * not specify a valid MIDI message
	 *
	 * @see #setMessage(int, int, int)
	 * @see #setMessage(int)
	 * @see #getCommand
	 * @see #getChannel
	 * @see #getData1
	 * @see #getData2
	 */
	public void setMessage(int command, int channel, int data1, int data2) throws InvalidMidiDataException{
		// check for valid values
		if (command >= 0xF0 || command < 0x80){
			throw new InvalidMidiDataException("command out of range: 0x" + Integer.toHexString(command));
		}
		if ((channel & 0xFFFFFFF0) != 0){ // <=> (channel<0 || channel>15)
			throw new InvalidMidiDataException("channel out of range: " + channel);
		}
		setMessage((command & 0xF0) | (channel & 0x0F), data1, data2);
	}

	/**
	 * Obtains the MIDI channel associated with this event.  This method
	 * assumes that the event is a MIDI channel message; if not, the return
	 * value will not be meaningful.
	 * @return MIDI channel associated with the message.
	 */
	int getChannel(){
		// this returns 0 if an invalid message is set
		return (getStatus() & 0x0F);
	}

	void setChannel(final int i_midiChannel){
		data[0] = (byte) (data[0] | (i_midiChannel & 0x0F));
	}

	/**
	 * Obtains the MIDI command associated with this event.  This method
	 * assumes that the event is a MIDI channel message; if not, the return
	 * value will not be meaningful.
	 */
	public int getCommand(){
		// this returns 0 if an invalid message is set
		return (getStatus() & 0xF0);
	}

	public void setCommand(final int i_command){
		data[0] = (byte) (data[0] | (i_command & 0xF0));
	}

	/**
	 * Obtains the first data byte in the message.
	 * @return the value of the <code>data1</code> field
	 * @see #setMessage(int, int, int)
	 */
	public int getData1(){
		if (length > 1){
			return (data[1] & 0xFF);
		}
		return 0;
	}

	public void setData1(final int i_data1){
		data[1] = (byte) (i_data1 & 0xFF);
	}

	/**
	 * Obtains the second data byte in the message.
	 * @return the value of the <code>data2</code> field
	 * @see #setMessage(int, int, int)
	 */
	public int getData2(){
		if (length > 2){
			return (data[2] & 0xFF);
		}
		return 0;
	}

	public void setData2(final int i_data2){
		data[1] = (byte) (i_data2 & 0xFF);
	}

	/**
	 * Retrieves the number of data bytes associated with a particular
	 * status byte value.
	 * @param status status byte value, which must represent a short MIDI message
	 * @return data length in bytes (0, 1, or 2)
	 * @throws <code>InvalidMidiDataException</code> if the
	 * <code>status</code> argument does not represent the status byte for any
	 * short message
	 */
	protected final int getDataLength(int status) throws InvalidMidiDataException{
		// system common and system real-time messages
		switch (status){
			case 0xF6: // Tune Request
			case 0xF7: // EOX
			// System real-time messages
			case 0xF8: // Timing Clock
			case 0xF9: // Undefined
			case 0xFA: // Start
			case 0xFB: // Continue
			case 0xFC: // Stop
			case 0xFD: // Undefined
			case 0xFE: // Active Sensing
			case 0xFF: // System Reset
				return 0;
			case 0xF1: // MTC Quarter Frame
			case 0xF3: // Song Select
				return 1;
			case 0xF2: // Song Position Pointer
				return 2;
			default:
		}

		// channel voice and mode messages
		switch (status & 0xF0){
			case 0x80:
			case 0x90:
			case 0xA0:
			case 0xB0:
			case 0xE0:
				return 2;
			case 0xC0:
			case 0xD0:
				return 1;
			default:
				throw new InvalidMidiDataException("Invalid status byte: " + status);
		}
	}

	/**
	 * Creates a new object of the same class and with the same contents
	 * as this object.
	 * @return a clone of this instance.
	 */
	public Object clone(){
		byte[] newData = new byte[length];
		System.arraycopy(data, 0, newData, 0, newData.length);

		MidiEvent msg = new MidiEvent(newData);
		return msg;
	}
}
/*
Part of the proMIDI lib - http://texone.org/promidi

Copyright (c) 2005 Christian Riekoff

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General
Public License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA  02111-1307  USA
*/

package promidi;

/**
 * This class olds the constants for the quantization of the
 * tracks and patterns.
 * @author christianr
 *
 */
public class Q{

	public static final int _1_2 = 256;
	public static final int _1_3 = 171;
	public static final int _1_4 = 128;
	public static final int _1_6 = 85;
	public static final int _1_8 = 64;
	public static final int _1_16 = 32;
	public static final int _1_32 = 16;
	public static final int _1_64 = 8;
	public static final int NONE = 1;

}
/*
Part of the proMIDI lib - http://texone.org/promidi

Copyright (c) 2005 Christian Riekoff

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General
Public License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA  02111-1307  USA
*/

package promidi;

import promidi.Controller;
import promidi.Note;

abstract class MidiEventProcessor{

	long startTick;

	long endTick;

	boolean[] channels = new boolean[16];

	abstract void processNoteEvent(Note event);

	abstract void processControllerEvent(Controller event);

	/**
	 * Set channels that may pass through the filter
	 * @param channels Array of integers containing channel numbers
	 */
	void setChannels(int[] channels){
		for (int n = 0; n < 16; n++)
			this.channels[n] = false;
		for (int i = 0; i < channels.length; i++)
			this.channels[i] = true;
	}

	boolean canProcessChannel(int channel){
		return channels[channel];
	}

	long getStartTick(){
		return startTick;
	}

	void setStartTick(long startTick){
		this.startTick = startTick;
	}

	long getEndTick(){
		return endTick;
	}

	void setEndTick(long endTick){
		this.endTick = endTick;
	}

}
/*
Part of the proMIDI lib - http://texone.org/promidi

Copyright (c) 2005 Christian Riekoff

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General
Public License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA  02111-1307  USA
*/

package promidi;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.ArrayList;

/**
 * A sequencer describes a device that records and plays back a sequence
 * of control information for any electronic musical instrument. The proMIDI
 * Sequencer allows you you to record and playback MIDI data.
 * <br><br>
 * The minimal time resolution of a sequencer is a tick. The proMIDI sequencer
 * has a rate of 512 ticks per bar. 
 * @example promidi_sequencer
 * @related Song
 * @related Track
 */
public class Sequencer implements Runnable{

	/**
	 * Holds the song that is played by the sequencer
	 */
	private Song song;

	private int loopCount;

	private long loopStartPoint;

	private long loopEndPoint;

	private float bpm;

	private boolean recording;

	private List songPositionListeners = new ArrayList();

	private boolean running;

	private boolean finished = true;

	/**
	 * Keeps the System time on start of sequencer
	 */
	static long startTimeMillis;

	private long lastTickPosition;

	private long startTickPosition;
	
	/**
	 * The actual playback position as tick
	 */
	private long tickPosition;

	/**
	 * The number of loops played by the sequencer
	 */
	private int playedLoops;

	

	Thread playThread;

	/**
     * A value indicating that looping should continue
     * indefinitely rather than complete after a specific
     * number of loops.
     */
    public static final int LOOP_CONTINUOUSLY = -1;


	public Sequencer(){
	}

	/**
	 * Sets the song the sequencer has to play.
	 * @param i_song Song, the song the sequencer has to play
	 * @throws InvalidMidiDataException
	 * @example promidi_sequencer
	 * @related Sequencer
	 * @related Song
	 * @related setSong ( )
	 */
	public void setSong(final Song i_song){
		this.song = i_song;	
	}

	/**
	 * @invisible
	 * @param i_stream
	 * @throws IOException
	 * @throws InvalidMidiDataException
	 */
	public void setSong(final InputStream i_stream) throws IOException{

	}

	/**
	 * Returns the song the sequencer is currently playing
	 * @return Song, the song the sequencer is playing
	 * @related Sequencer
	 * @related Song
	 * @related getSong ( )
	 */
	public Song getSong(){
		return song;
	}

	/**
	 * @invisible
	 * @param track
	 * @param channel
	 */
	public void recordEnable(final Track track, final int channel){
		// TODO Auto-generated method stub

	}

	/**
	 * @invisible
	 * @param track
	 */
	public void recordDisable(final Track track){
		// TODO Auto-generated method stub

	}

	/**
	 * Returns the actual tempo of the sequencer in BPM.
	 * @return float, the tempo of the sequencer in BPM
	 * @related Sequencer
	 * @related setTempoInBPM ( )
	 */
	public float getTempoInBPM(){
		return song.getTempo();
	}

	/**
	 * Sets the actual tempo of the sequencer in BPM.
	 * @param bpm float, the new tempo of the sequencer in BPM
	 * @related Sequencer
	 * @related getTempoInBPM ( )
	 */
	public void setTempoInBPM(final float bpm){
		this.bpm = bpm;

	}

	/**
	 * Returns the actual position of the sequencer in the actual
	 * song in ticks.
	 * @return long, the actual position of the sequencer in ticks.
	 * @related Sequencer
	 * @related setTickPosition ( )
	 */
	public long getTickPosition(){
		return tickPosition;
	}

	/**
	 * Sets the actual position of the sequencer in ticks.
	 * @param tickPosition long, actual position of the sequencer
	 * @related Sequencer
	 * @related getTickPosition ( )
	 */
	public void setTickPosition(final long tickPosition){
		startTickPosition = tickPosition;
		startTimeMillis = System.currentTimeMillis();
		this.lastTickPosition = tickPosition;
	}

	/**
	 * @invisible
	 * @param track
	 * @param mute
	 */
	public void setTrackMute(final int track, final boolean mute){
		// TODO Auto-generated method stub
	}

	/**
	 * @invisible
	 * @param track
	 * @return
	 */
	public boolean getTrackMute(final int track){
		// TODO Auto-generated method stub
		return false;
	}

	/**
	 * @invisible
	 * @param track
	 * @param solo
	 */
	public void setTrackSolo(final int track, final boolean solo){
		// TODO Auto-generated method stub

	}

	/**
	 * @invisible
	 * @param track
	 * @return 
	 */
	public boolean getTrackSolo(final int track){
		// TODO Auto-generated method stub
		return false;
	}

	/**
	 * Sets the startpoint of the loop the sequencer should play
	 * @param tick long, the startpoint of the loop
	 * @example promidi_sequencer
	 * @related Sequencer
	 * @related getLoopStartPoint ( )
	 * @related setLoopEndPoint ( )
	 * @related getLoopEndPoint ( )
	 */
	public void setLoopStartPoint(final long tick){
		this.loopStartPoint = tick;

	}

	/**
	 * Returns the startpoint of the loop the sequencer should play
	 * @return long, the startpoint of the loop
	 * @related Sequencer
	 * @related setLoopStartPoint ( )
	 * @related setLoopEndPoint ( )
	 * @related getLoopEndPoint ( )
	 */
	public long getLoopStartPoint(){
		return loopStartPoint;
	}

	/**
	 * Sets the endpoint of the loop the sequencer should play
	 * @param tick long, the endpoint of the loop
	 * @example promidi_sequencer
	 * @related Sequencer
	 * @related setLoopStartPoint ( )
	 * @related getLoopStartPoint ( )
	 * @related getLoopEndPoint ( )
	 */
	public void setLoopEndPoint(final long tick){
		this.loopEndPoint = tick;

	}

	/**
	 * Returns  the endpoint of the loop the sequencer should play
	 * @return long, the endpoint of the loop
	 * @related Sequencer
	 * @related setLoopStartPoint ( )
	 * @related getLoopStartPoint ( )
	 * @related setLoopEndPoint ( )
	 */
	public long getLoopEndPoint(){
		return loopEndPoint;
	}
	
	/**
	 * Tells the sequencer to permanently play the current loop
	 * @related Sequencer
	 * @related noLoop ( )
	 */
	public void loop(){
		setLoopCount(-1);
	}
	
	/**
	 * Tells the sequencer to stop playing the loop
	 * @related Sequencer
	 * @related loop ( )
	 */
	public void noLoop(){
		setLoopCount(0);
	}

	/**
	 * Sets how often the loop of the sequencer has to be played.
	 * @param count int, number of times the loop has to be played
	 * @example promidi_sequencer
	 * @related Sequencer
	 * @related getLoopCount ( )
	 */
	public void setLoopCount(int count){
		this.loopCount = count;
	}

	
	public int getLoopCount(){
		return loopCount;
	}

	/**
	 * Add a song position listener to the sequencer. See the
	 * SongPositionListener javadoc.
	 * @invisible
	 * @param songPositionListener
	 */
	public void addSongPositionListener(SongPositionListener songPositionListener){
		songPositionListeners.add(songPositionListener);
	}

	final void notifySongPositionListeners(long tick){
		for (int i = 0; i < songPositionListeners.size(); i++){
			((SongPositionListener) songPositionListeners.get(i)).notifyTickPosition(tick);
		}
	}
	
	/**
	 * Starts the sequencer.
	 * @example promidi_sequencer
	 * @related stop ( )
	 */
	public void start(){
		// Ensure that there is no other running thread
		running = false;
		while (!finished){
			Thread.yield();
		}

		finished = false;
		running = true;
		playedLoops = 0;
		startTimeMillis = System.currentTimeMillis();

		tickPosition = startTickPosition;
		resetControllers();

		playThread = new Thread(this);
		playThread.setPriority(Thread.MAX_PRIORITY - 1);
		playThread.start();
	}

	/**
	 * Stops the playback of the sequencer.
	 * @example promidi_sequencer
	 * @related start ( )
	 */
	public void stop(){
		recording = false;
		running = false;
		sendMidiPanic(false);
		startTickPosition = tickPosition;

	}

	/**
	 * Use this method to see if the sequencer is running.
	 * @return boolean: true if the sequencer is running otherwise false
	 */
	public boolean isRunning(){
		return running;
	}

	/**
	 * @invisible
	 *
	 */
	public void startRecording(){
		recording = true;
		start();
	}

	/**
	 * @invisible
	 *
	 */
	public void stopRecording(){
		stop();
	}

	/**
	 * @invisible
	 * @return
	 */
	public boolean isRecording(){
		return recording;
	}

	private void timerEvent(){
			long currentTick = startTickPosition + (long) ((System.currentTimeMillis() - startTimeMillis) * (song.resolution * (getTempoInBPM() / 60000)));

			// Note that this loop will always try to catch up if any ticks were missing.
			for (long playTick = lastTickPosition; playTick <= currentTick; playTick++){
				// Calculate real play tick regarding loop settings
				if (getLoopCount() == Sequencer.LOOP_CONTINUOUSLY && startTickPosition < getLoopEndPoint()){
					tickPosition = ((playTick - getLoopStartPoint()) % (getLoopEndPoint() - getLoopStartPoint())) + getLoopStartPoint();
				}else{
					tickPosition = playTick;
				}

				// Detect loop point and increase counter;
				if (tickPosition == (getLoopEndPoint() - 1)){
					playedLoops++;
				}

				// If we're starting a new loop, then stop hanging notes and chase Controllers
				if (playedLoops > 0 && tickPosition == getLoopStartPoint()){
					flushNoteOnCache();
					resetControllers();
				}
				
				// Now play every event on every track for the given tick
				for (int i = 0; i < song.getNumberOfTracks(); i++){
					Track track = song.getTrack(i);
					track.sendEventsForTick(tickPosition);
				}
				notifySongPositionListeners(tickPosition);
			}

			lastTickPosition = currentTick + 1;
	}

	/**
	 * Resets the controllers.
	 */
	private void resetControllers(){
		for (int i = 0; i < song.getNumberOfTracks(); i++){
			song.getTrack(i).resetControllers(tickPosition);
		}
	}

	/**
	 * Sends a noteOff for all actual notes.
	 */
	private void flushNoteOnCache(){
		for(int i = 0; i < song.getNumberOfTracks();i++){
			song.getTrack(i);
		}
	}



	
	void sendMidiPanic(boolean doControllers){
		try{
			for (int i = 0; i < song.getNumberOfTracks(); i++){
				song.getTrack(i).sendMidiPanic(doControllers);	
			}
		}catch (Exception e){
		}
	}


	/**
	 * @invisible
	 */
	public void run(){
		while (running){
			try{
				Thread.sleep(1);
				timerEvent();
			}catch (Exception e){
				e.printStackTrace();
			}
		}
		finished = true;
	}

	/**
	 * @invisible
	 * @return 
	 */
	public long getRealTimeTickPosition(){
		long currentTick = startTickPosition + (long) ((System.currentTimeMillis() - startTimeMillis) * (song.resolution * (getTempoInBPM() / 60000)));

		if (getLoopCount() == Sequencer.LOOP_CONTINUOUSLY){
			currentTick = ((currentTick - getLoopStartPoint()) % (getLoopEndPoint() - getLoopStartPoint())) + getLoopStartPoint();
		}

		return (currentTick);
	}
}
/*
 Part of the proMIDI lib - http://texone.org/promidi

 Copyright (c) 2005 Christian Riekoff

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General
 Public License along with this library; if not, write to the
 Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 Boston, MA  02111-1307  USA
 */

package promidi;

import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;
import java.util.Vector;

import javax.sound.midi.MidiSystem;
import javax.sound.midi.MidiUnavailableException;

/**
 * MidiIO is the base class for managing the available midi ports. 
 * It provides you with methods to get information on your ports and 
 * to open them. There are various changes on the new proMIDI version
 * in handling inputs and outputs. Instead of opening a complete port
 * you can now open inputs and outputs with a channel number and a 
 * port name or number. To start use the printDevices method to get
 * all devices available on your system.
 * @example promidi_midiio
 * @related MidiOut
 * @related Note
 * @related Controller
 * @related ProgramChange
 * @related printDevices ( )
 */
public class MidiIO{

	/**
	 * PApplet proMidi is running in
	 */
	processing.core.PApplet parent;

	/**
	 * Method to check if the parent Applet calls noteOn
	 */
	Method noteOnMethod;

	/**
	 * Method to check if the parent Applet calls noteOn
	 */
	Method noteOffMethod;

	/**
	 * Method to check if the parent Applet calls controllerIn
	 */
	Method controllerMethod;

	/**
	 * Method to check if the parent Applet calls programChange
	 */
	Method programChangeMethod;

	/**
	 * Stores all available midi input devices
	 */
	final private Vector midiInputDevices = new Vector();

	/**
	 * Stores all available midi output devices
	 */
	final private Vector midiOutDevices = new Vector();

	/**
	 * Contains all open midiouts
	 */
	final private Map openMidiOuts = new HashMap();

	/**
	 * Stores the MidiIO instance;
	 */
	private static MidiIO instance;

	/**
	 * Initialises a new MidiIO object.
	 * @param parent
	 */
	private MidiIO(processing.core.PApplet parent){
		this.parent = parent;
		parent.registerDispose(this);

		try{
			noteOnMethod = parent.getClass().getMethod("noteOn", new Class[] {Note.class,Integer.TYPE,Integer.TYPE});
		}catch (Exception e){
			// no such method, or an error.. which is fine, just ignore
		}
		try{
			noteOffMethod = parent.getClass().getMethod("noteOff", new Class[] {Note.class,Integer.TYPE,Integer.TYPE});
		}catch (Exception e){
			// no such method, or an error.. which is fine, just ignore
		}
		try{
			controllerMethod = parent.getClass().getMethod("controllerIn", new Class[] {Controller.class,Integer.TYPE,Integer.TYPE});
		}catch (Exception e){
			// no such method, or an error.. which is fine, just ignore
		}
		try{
			programChangeMethod = parent.getClass().getMethod("programChange", new Class[] {ProgramChange.class,Integer.TYPE,Integer.TYPE});
		}catch (Exception e){
			// no such method, or an error.. which is fine, just ignore
		}
		getAvailablePorts();
	}

	private MidiIO(){
		getAvailablePorts();
	}

	/**
	 * Use this method to get instance of MidiIO. It makes sure that only one 
	 * instance of MidiIO is initialized. You have to give this method a reference to 
	 * your applet, to let promidi communicate with it.
	 * @param parent PApplet, reference to the parent PApplet
	 * @return MidiIO, an instance of MidiIO for midi communication
	 * @example promidi_midiio
	 * @shortdesc Use this method to get instance of MidiIO.
	 * @related openInput ( )
	 * @related getMidiOut ( )
	 * @related printDevices ( )
	 */
	public static MidiIO getInstance(processing.core.PApplet parent){
		if (instance == null){
			instance = new MidiIO(parent);
		}
		return instance;
	}

	public static MidiIO getInstance(){
		if (instance == null){
			instance = new MidiIO();
		}
		return instance;
	}

	/**
	 * Throws an exception if an invalid midiChannel number is put in
	 * @param i_midiChannel
	 * @invisible
	 */
	public static void checkMidiChannel(final int i_midiChannel){
		if (i_midiChannel < 0 || i_midiChannel > 15){
			throw new RuntimeException("Invalid midiChannel make sure you have a channel number between 0 and 15.");
		}
	}

	/**
	 * The dispose method to close all opened ports.
	 * @invisible
	 */
	public void dispose(){
		closePorts();
	}

	/**
	 * Method to get all available midi ports and add them to the corresponding
	 * device list.
	 */
	private void getAvailablePorts(){
		javax.sound.midi.MidiDevice.Info[] infos = MidiSystem.getMidiDeviceInfo();
		for (int i = 0; i < infos.length; i++){
			try{
				javax.sound.midi.MidiDevice theDevice = MidiSystem.getMidiDevice (infos[i]);
				
				if (theDevice instanceof javax.sound.midi.Sequencer) {
					// Ignore this device as it's a sequencer
				}else if (theDevice.getMaxReceivers () != 0) {
					midiOutDevices.add(theDevice);
				}else if (theDevice.getMaxTransmitters () != 0) {
					midiInputDevices.add(theDevice);
				}
			}catch (MidiUnavailableException e){
				e.printStackTrace();
			}
		}
	}

	/**
	 * Use this method to get the number of available midi input devices.
	 * @return int, the number of available midi inputs
	 * @example promidi_midiio
	 * @related numberOfOutputDevices ( )
	 * @related getInputDeviceName ( )
	 * @related getOutputDeviceName ( )
	 */
	public int numberOfInputDevices(){
		return midiInputDevices.size();
	}

	/**
	 * Use this method to get the number of available midi output devices.
	 * @return int, the number of available midi output devices.
	 * @example promidi_midiio
	 * @related numberOfInputDevices ( )
	 * @related getInputDeviceName ( )
	 * @related getOutputDeviceName ( )
	 */
	public int numberOfOutputDevices(){
		return midiOutDevices.size();
	}

	/**
	 * Use this method to get the name of an input device.
	 * @param input int, number of the input
	 * @return String, the name of the input
	 * @example promidi_midiio
	 * @related numberOfInputDevices ( )
	 * @related numberOfOutputDevices ( )
	 * @related getOutputDeviceName ( )
	 */
	public String getInputDeviceName(final int input){
		return ((MidiInDevice) midiInputDevices.get(input)).getName();
	}

	/**
	 * Use this method to get the name of an output device.
	 * @param output int, number of the output
	 * @return String, the name of the output
	 * @example promidi_midiio
	 * @related numberOfInputDevices ( )
	 * @related numberOfOutputDevices ( )
	 * @related getInputDeviceName ( )
	 */
	public String getOutputDeviceName(final int output){
		return ((MidiOutDevice) midiOutDevices.get(output)).getName();
	}

	/**
	 * Use this method for a simple trace of all available midi input devices.
	 * @example promidi_midiio
	 * @related printOutputDevices ( )
	 * @related printDevices ( )
	 */
	public void printInputDevices(){
		System.out.println("<< inputs: >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
		for (int i = 0; i < numberOfInputDevices(); i++){
			System.out.println("input " + /*parent.nf(*/i/*,2)*/+ " : " + getInputDeviceName(i));
		}
	}

	/**
	 * Use this method for a simple trace of all available midi output devices.
	 * @example promidi_midiio
	 * @related printInputDevices ( )
	 * @related printDevices ( )
	 */
	public void printOutputDevices(){
		System.out.println("<< outputs: >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
		for (int i = 0; i < numberOfOutputDevices(); i++){
			System.out.println("output " + /*parent.nf(*/i/*,2)*/+ " : " + getOutputDeviceName(i));
		}
	}

	/**
	 * Use this method for a simple trace of all midi devices. Call
	 * this method before working with proMIDI to get the numbers and
	 * names of the installed devices
	 * @example promidi_midiio
	 * @shortdesc Use this method for a simple trace of all midi devices.
	 * @related printInputDevices ( )
	 * @related printOutputDevices ( )
	 */
	public void printDevices(){
		printInputDevices();
		printOutputDevices();
		System.out.println("<<>>>>>>>>> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
	}

	/**
	 * Use this Methode to open an input device. You can open an 
	 * input device with its number or with its name. Once a input device is opened 
	 * it is reserved for your program. All opened devices are closed 
	 * by promidi when you close your application. You can also close opened devices 
	 * on your own.<br>
	 * Note that you open inputs with midi channels now, this makes you more
	 * flexible with handling incoming mididata. Instead of opening an input and
	 * analysing the incoming events in noteOn, controllerIn, noteOff or programChange
	 * you could use the plug method to directly forward the incoming events to
	 * a method and object of your choice.
	 * @param inputDeviceNumber int, number of the inputdevice to open
	 * @param midiChannel int, the midichannel of the input to open
	 * @shortdesc Use this Methode to open an input device.
	 * @example promidi_reflection
	 * @related getMidiOut ( )
	 * @related plug ( )
	 */
	public void openInput(
		final int inputDeviceNumber, 
		final int midiChannel
	){
		checkMidiChannel(midiChannel);
		MidiInDevice midiInDevice = (MidiInDevice) midiInputDevices.get(inputDeviceNumber);
		midiInDevice.open();
		midiInDevice.openMidiChannel(midiChannel);
	}

	/**
	 * @param inputDeviceName String, name of the input to open
	 */
	public void openInput(final String inputDeviceName, final int midiChannel){
		checkMidiChannel(midiChannel);
		for (int i = 0; i < numberOfInputDevices(); i++){
			MidiInDevice midiInDevice = (MidiInDevice) midiInputDevices.get(i);
			if (midiInDevice.getName().equals(inputDeviceName)){
				midiInDevice.open();
				midiInDevice.openMidiChannel(midiChannel);
			}
		}
		throw new RuntimeException("There is no input device with the name " + inputDeviceName + ".");
	}

	/**
	 * Plug is a handy method to handle incoming midiEvents. To create a plug
	 * you have to implement a method that gets a Note, a Controller or a ProgramChange
	 * as input parameter. Now you can plug these methods using this method and
	 * the correspoding midievents are send to the plugged method.
	 * @param i_object Object: the object thats method has to plugged
	 * @param i_methodName String: the name of the method that has to be plugged
	 * @param i_intputDeviceNumber int: the number of the device thats events areto the plug
	 * @param i_midiChannel int: the midichannel thats events areto the plug
	 * @example promidi_plug
	 * @shortdesc Plugs a method to handle incoming MidiEvents.
	 * @related Note
	 * @related Controller
	 * @related ProgramChange
	 */
	public void plug(
		final Object i_object, 
		final String i_methodName, 
		final int i_intputDeviceNumber, 
		final int i_midiChannel
	){
		MidiInDevice midiInDevice = (MidiInDevice) midiInputDevices.get(i_intputDeviceNumber);
		midiInDevice.plug(i_object,i_methodName,i_midiChannel);
	}

	/**
	 * Use this Methode to open an output. You can open an 
	 * output with its number or with its name. Once the output is opened 
	 * it is reserved for your program. All opened ports are closed 
	 * by promidi when you close your applet. You can also close opened Ports 
	 * on your own.
	 * @param outDeviceNumber int, number of the output to open
	 * @shortdesc Use this Methode to open an output.
	 * @example promidi
	 * @related openInput ( )
	 */
	public MidiOut getMidiOut(final int midiChannel, final int outDeviceNumber){
		checkMidiChannel(midiChannel);
		try{
			final String key = midiChannel + "_" + outDeviceNumber;
			if (!openMidiOuts.containsKey(key)){
				MidiOutDevice midiOutDevice = (MidiOutDevice) midiOutDevices.get(outDeviceNumber);
				midiOutDevice.open();
				final MidiOut midiOut = new MidiOut(midiChannel, midiOutDevice);
				openMidiOuts.put(key, midiOut);
			}
			return (MidiOut) openMidiOuts.get(key);
		}catch (RuntimeException e){
			e.printStackTrace();
			throw new RuntimeException("You wanted to open the unavailable output " + outDeviceNumber + ". The available outputs are 0 - " + (numberOfOutputDevices() - 1) + ".");
		}
	}

	/**
	 * @param outDeviceName String, name of the Output to open
	 */
	public MidiOut getMidiOut(final int midiChannel, final String outDeviceName){
		for (int i = 0; i < numberOfOutputDevices(); i++){
			MidiOutDevice midiOutDevice = (MidiOutDevice) midiOutDevices.get(i);
			if (midiOutDevice.getName().equals(outDeviceName)){
				return getMidiOut(midiChannel, i);
			}
		}
		throw new UnavailablePortException("There is no output with the name " + outDeviceName + ".");
	}

	/**
	 * Use this Methode to close an input. You can close it with its number or name. 
	 * There is no need of closing the ports, as promidi closes them when the applet 
	 * is closed.
	 * @param inputNumber int, number of the input to close
	 */
	public void closeInput(int inputNumber){
		try{
			MidiInDevice inDevice = (MidiInDevice) midiInputDevices.get(inputNumber);
			inDevice.close();
		}catch (ArrayIndexOutOfBoundsException e){
			throw new UnavailablePortException("You wanted to close the unavailable input " + inputNumber + ". The available inputs are 0 - " + (midiInputDevices.size() - 1) + ".");
		}

	}

	/**
	 * @param outputName String, name of the Input to close
	 */
	public void closeInput(String inputName){
		for (int i = 0; i < numberOfInputDevices(); i++){
			MidiInDevice inDevice = (MidiInDevice) midiInputDevices.get(i);
			if (inDevice.getName().equals(inputName)){
				closeInput(i);
				return;
			}
		}
		throw new UnavailablePortException("There is no input with the name " + inputName + ".");
	}

	/**
	 * Use this Methode to close an output. You can close it with its number or name. 
	 * There is no need of closing the ports, as promidi closes them when the applet 
	 * is closed.
	 * @invisible
	 * @param outputNumber int, number of the output to close
	 */
	public void closeOutput(int outputNumber){
		try{
			MidiOutDevice outDevice = (MidiOutDevice) midiOutDevices.get(outputNumber);
			outDevice.close();
		}catch (ArrayIndexOutOfBoundsException e){
			throw new UnavailablePortException("You wanted to close the unavailable output " + outputNumber + ". The available outputs are 0 - " + (midiOutDevices.size() - 1) + ".");
		}
	}

	/**
	 * @invisible
	 * @param outputName String, name of the Output to close
	 */
	public void closeOutput(String outputName){
		for (int i = 0; i < numberOfOutputDevices(); i++){
			MidiOutDevice outDevice = (MidiOutDevice) midiOutDevices.get(i);
			if (outDevice.getName().equals(outputName)){
				closeOutput(i);
				return;
			}
		}
		throw new UnavailablePortException("There is no output with the name " + outputName + ".");
	}

	/**
	 * Use this Methode to close all opened inputs. 
	 * There is no need of closing the ports, as promidi closes them when the applet 
	 * is closed.
	 * @invisible
	 */
	public void closeInputs(){
		for (int i = 0; i < numberOfInputDevices(); i++){
			closeInput(i);
		}
	}

	/**
	 * Use this Methode to close all opened outputs. 
	 * There is no need of closing the ports, as promidi closes them when the applet 
	 * is closed.
	 * @invisible
	 */
	public void closeOutputs(){
		for (int i = 0; i < numberOfOutputDevices(); i++){
			closeOutput(i);
		}
	}

	/**
	 * Use this Methode to close all opened ports. 
	 * There is no need of closing the ports, as promidi closes them when applet 
	 * is closed.
	 * @invisible
	 */
	public void closePorts(){
		closeInputs();
		closeOutputs();
	}
}
/*
Part of the proMIDI lib - http://texone.org/promidi

Copyright (c) 2005 Christian Riekoff

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General
Public License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA  02111-1307  USA
*/

package promidi;

import java.util.SortedMap;
import java.util.TreeMap;
import java.util.Vector;

/**
 * A song is a data structure containing musical information 
 * that can be played back by the proMIDI sequencer object. Specifically, the
 * song contains timing information and one or more tracks.  Each track consists of a
 * series of MIDI events (such as note-ons, note-offs, program changes, and meta-events).
 * <br><br>
 * A sequence can be built from scratch by adding new
 * tracks to an empty song, and adding MIDI events to these tracks.
 */
public class Song{
	/**
	 * keeps the tracks of the song
	 */
    private Vector songTracks = new Vector();
	
	
	/**
	 * Set to keep all ticks with events
	 */
	private SortedMap ticks = new TreeMap();
	
	/**
	 * Name of the song
	 */
	private String name = "";
	
	/**
	 * tempo of the song
	 */
	private float tempo = 120;
	
   /**
    * The timing resolution of the song.
    * @see #getResolution
    */
   protected int resolution;

	public Song(final int resolution){
		this.resolution = resolution;
	}
	
	/**
	 * Builds a new Song with a name, and a tempo.
	 * @param name String, name of the song
	 * @param tempo float, tempo of the song
	  * @throws InvalidMidiDataException
	 */
	public Song(String name,float tempo){
		this(128);
		this.name = name;
		this.tempo = tempo;
	}
	
	/**
	 * Adds a new track to a song.
	 * @param i_track Track, track to add to the song
	 */
	public void addTrack(final Track i_track){
		if(!songTracks.contains(i_track)){
			songTracks.addElement(i_track);
			i_track.setSong(this);
		}
	}
	
	/**
	 * Removes a track from a song
	 * @param track Track, track to remove from the song
	 */
	public void removeTrack(Track track){
		songTracks.removeElement(track);
	}
	
	void addTick(long tick){
		Long objectTick = new Long(tick);
		if(!ticks.containsKey(objectTick)){
			ticks.put(objectTick,new Integer(0));
		}
	}
	
	/**
	 * Returns the number of tracks of this song
	 * @return the number of tracks
	 */
	public int getNumberOfTracks(){
		return songTracks.size();
	}
	
	/**
	 * Returns the track with the given number
	 * @param i int, number of the track
	 * @return Track, the track with the given number
	 */
	public Track getTrack(int i){
		return (Track)songTracks.get(i);
	}

	/**
	 * Returns the name of a song.
	 * @return String, name of the song
	 */
	public String getName(){
		return name;
	}

	/**
	 * Sets the name name of a song.
	 * @param name String, new name for the song
	 */
	public void setName(String name){
		this.name = name;
	}

	/**
	 * Returns the tempo of a song in BPM.
	 * @return float, tempo of the song
	 */
	public float getTempo(){
		return tempo;
	}

	/**
	 * Sets the tempo of a song.
	 * @param tempo float, new tempo for the song
	 */
	public void setTempo(float tempo){
		this.tempo = tempo;
	}
}
/*
Part of the proMIDI lib - http://texone.org/promidi

Copyright (c) 2005 Christian Riekoff

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General
Public License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA  02111-1307  USA
*/

package promidi;

import java.util.ArrayList;
import java.util.List;

/**
 * Handles the incoming midi data defined by an an midi device and
 * an midichannel
 * @author tex
 *
 */
class MidiIn{
	/**
	 * The midichannel of the midiout
	 */
	final int midiChannel;

	/**
	 * The midi context holding the methods implemented
	 * in PApplet to invoke on incoming midi events
	 */
	private final MidiIO promidiContext;
	
	/**
	 * List of plugs to handle midi events
	 */
	private final List plugEventList;
	
	/**
	 * List of plugs handling incoming notes
	 */
	private final List plugNoteList;
	
	/**
	 * List of plugs handling incomming controller
	 */
	private final List plugControllerList;
	
	/**
	 * List of plugs handling incoming programchanges
	 */
	private final List plugProgramChangeList;
	
	/**
	 * Initializes a new MidiOutput.
	 * @param i_midiChannel int, the midiChannel of the midiout
	 * @param i_midiInDevice MidiOutPort, the midi port of the midiout
	 */
	MidiIn(final int i_midiChannel,final MidiIO i_promidiContext){
		midiChannel = i_midiChannel;
		promidiContext = i_promidiContext;
		
		plugEventList = new ArrayList();
		plugNoteList = new ArrayList();
		plugControllerList = new ArrayList();
		plugProgramChangeList = new ArrayList();
	}

	/**
	 * Looks if two MidiOuts are equal. This is the case if they have
	 * the same midiChannel and port.
	 * @return true, if the given object is equal to the MidiOut
	 */
	public boolean equals(final Object object){
		if(!(object instanceof MidiOutDevice))return false;
		final MidiIn midiOut = (MidiIn)object;
		if(midiChannel != midiOut.midiChannel) return false;
		return true;
	}	
	
	/**
	 * plugs a method with the given name of the given object
	 * @param i_object
	 * @param i_methodName
	 */
	void plug(
		final Object i_object, 
		final String i_methodName
	){
		List plugList;
		Plug plug = new Plug(i_object,i_methodName);
		switch(plug.getParameterKind()){
			case Plug.MIDIEVENT:
				plugList = plugEventList;
				break;
			case Plug.NOTE:
				plugList = plugNoteList;
				break;	
			case Plug.CONTROLLER:
				plugList = plugControllerList;
				break;
			case Plug.PROGRAMCHANGE:
				plugList = plugProgramChangeList;
				break;
			default:
				throw new RuntimeException("Error on plug "+i_methodName+" check the given event type");
		}
		
		plugList.add(plug);
	}

	/**
	 * Use this method to send a control change to the midioutput. You can send 
	 * control changes to change the sound on midi sound sources for example.
	 * @param controller Controller: the controller you want to send.
	 * @param deviceNumber 
	 */
	void sendController(
		final Controller controller,
		final int deviceNumber,
		final int midiChannel
	){
		try{
			if (promidiContext.controllerMethod != null)
				promidiContext.controllerMethod.invoke(
					promidiContext.parent, 
					new Object[] {
						controller,
						new Integer(deviceNumber),
						new Integer(midiChannel)
					}
				);
		}catch (Exception e){
			System.err.println("Disabling controller() for " + promidiContext.parent.getName() + " because of an error.");
			e.printStackTrace();
			promidiContext.controllerMethod = null;
		}
		
		for(int i = 0; i < plugControllerList.size();i++){
			((Plug)plugControllerList.get(i)).callPlug(controller);
		}
	}

	/**
	 * With this method you can send a note on to your midi output. You can send note on commands
	 * to trigger midi soundsources. Be aware that you have to take care to send note off commands
	 * to release the notes otherwise you get midi hang ons.
	 * @param note Note, the note you want to send the note on for
	 */
	void sendNoteOn(
		final Note note,
		final int deviceNumber,
		final int midiChannel
	){
		try{
			if (promidiContext.noteOnMethod != null)
				promidiContext.noteOnMethod.invoke(
					promidiContext.parent, 
					new Object[] {
						note,
						new Integer(deviceNumber),
						new Integer(midiChannel)
					}
				);
		}catch (Exception e){
			System.err.println("Disabling noteOn() for " + promidiContext.parent.getName() + " because of an error.");
			e.printStackTrace();
			promidiContext.noteOnMethod = null;
		}
		
		for(int i = 0; i < plugNoteList.size();i++){
			((Plug)plugNoteList.get(i)).callPlug(note);
		}
	}

	/**
	 * Use this method to send a note off command to your midi output. You have to send note off commands 
	 * to release send note on commands.
	 * @param note Note, the note you want to send the note off for
	 */
	void sendNoteOff(
		final Note note,
		final int deviceNumber,
		final int midiChannel
	){
		note.setToNoteOff();
		sendNoteOn(note,deviceNumber,midiChannel);
		try{
			if (promidiContext.noteOffMethod != null)
				promidiContext.noteOffMethod.invoke(
					promidiContext.parent, 
					new Object[] {
						note,
						new Integer(deviceNumber),
						new Integer(midiChannel)
					}
				);		
		}catch (Exception e){
			System.err.println("Disabling noteOff() for " + promidiContext.parent.getName() + " because of an error.");
			e.printStackTrace();
			promidiContext.noteOffMethod = null;
		}
		
		for(int i = 0; i < plugNoteList.size();i++){
			((Plug)plugNoteList.get(i)).callPlug(note);
		}
	}

	/**
	 * With this method you can send program changes to your midi output. Program changes are used 
	 * to change the preset on a midi sound source.
	 */
	void sendProgramChange(
		final ProgramChange programChange,
		final int deviceNumber,
		final int midiChannel
	){
		try{
			if (promidiContext.programChangeMethod != null)
				promidiContext.programChangeMethod.invoke(
					promidiContext.parent, 
					new Object[] {
						programChange,
						new Integer(deviceNumber),
						new Integer(midiChannel)
					}
				);
		}catch (Exception e){
			System.err.println("Disabling programChange() for " + promidiContext.parent.getName() + " because of an error.");
			e.printStackTrace();
			promidiContext.programChangeMethod = null;
		}
		
		for(int i = 0; i < plugProgramChangeList.size();i++){
			((Plug)plugProgramChangeList.get(i)).callPlug(programChange);
		}
	}
}
/*
Part of the proMIDI lib - http://texone.org/promidi

Copyright (c) 2005 Christian Riekoff

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General
Public License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA  02111-1307  USA
*/

package promidi;

/**
 * Use this interface to implement any component that depend on the song position.
 * This could be a metronome, a graphical song position indicator etc.
 */
interface SongPositionListener {
    /**
     * This method is called each time a new tick is played by the sequencer. Note
     * that this method should return as soon as possible (immediately).
     * @param tick
     */
    void notifyTickPosition(long tick);
}
/*
Part of the proMIDI lib - http://texone.org/promidi

Copyright (c) 2005 Christian Riekoff

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General
Public License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA  02111-1307  USA
*/

package promidi;

import javax.sound.midi.MidiMessage;
import javax.sound.midi.MidiUnavailableException;
import javax.sound.midi.Receiver;
import javax.sound.midi.ShortMessage;
import javax.sound.midi.Transmitter;

class MidiInDevice extends MidiDevice implements Receiver{

	private final Transmitter inputTrans;

	private final MidiIO promidiContext;
	
	/**
	 * Contains the states of the 16 midi channels for a device.
	 * true if open otherwise false.
	 */
	private final MidiIn[] midiIns = new MidiIn [16];

	/**
	 * Initializes a new MidiIn.
	 * @param libContext
	 * @param midiDevice
	 * @throws MidiUnavailableException
	 */
	MidiInDevice(
		final MidiIO libContext, 
		final javax.sound.midi.MidiDevice midiDevice, 
		final int deviceNumber
	){
		super(midiDevice, deviceNumber);
		this.promidiContext = libContext;
		
		try{
			inputTrans = midiDevice.getTransmitter();
		}catch (MidiUnavailableException e){
			throw new RuntimeException();
		}
	}
	
	String getName(){
		return midiDevice.getDeviceInfo().getName();
	}
	
	void open(){
		super.open();
		inputTrans.setReceiver(this);
	}
	
	void openMidiChannel(final int i_midiChannel){
		if(midiIns[i_midiChannel]==null)
			midiIns[i_midiChannel] = new MidiIn(i_midiChannel,promidiContext);
	}
	
	void closeMidiChannel(final int i_midiChannel){
		midiIns[i_midiChannel]=null;
	}
	
	void plug(
		final Object i_object, 
		final String i_methodName, 
		final int i_midiChannel
	){
		open();
		openMidiChannel(i_midiChannel);
		midiIns[i_midiChannel].plug(i_object,i_methodName);
	}

	/**
	 * Sorts the incoming MidiIO data in the different Arrays.
	 * @invisible
	 * @param message MidiMessage
	 * @param deltaTime long
	 */
	public void send(final MidiMessage message, final long deltaTime){
		final ShortMessage shortMessage = (ShortMessage) message;

		// get messageInfos
		final int midiChannel = shortMessage.getChannel();

		if (midiIns[midiChannel] == null)
			return;

		final int midiCommand = shortMessage.getCommand();
		final int midiData1 = shortMessage.getData1();
		final int midiData2 = shortMessage.getData2();

		if (midiCommand == MidiEvent.NOTE_ON && midiData2 > 0){
			final Note note = new Note(midiData1, midiData2);
			midiIns[midiChannel].sendNoteOn(note,deviceNumber,midiChannel);
		}else if (midiCommand == MidiEvent.NOTE_OFF || midiData2 == 0){
			final Note note = new Note(midiData1, midiData2);
			midiIns[midiChannel].sendNoteOff(note,deviceNumber,midiChannel);
		}else if (midiCommand == MidiEvent.CONTROL_CHANGE){
			final Controller controller = new Controller(midiData1, midiData2);
			midiIns[midiChannel].sendController(controller,deviceNumber,midiChannel);
		}else if (midiCommand == MidiEvent.PROGRAM_CHANGE){
			final ProgramChange programChange = new ProgramChange(midiData1);
			midiIns[midiChannel].sendProgramChange(programChange,deviceNumber,midiChannel);
		}
	}
}
/*
Part of the proMIDI lib - http://texone.org/promidi

Copyright (c) 2005 Christian Riekoff

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General
Public License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA  02111-1307  USA
*/
package promidi;

import java.util.HashMap;
import java.util.Vector;


/**
 * This class is for the mapping of the midievents of a sequence to the different ticks.
 *
 */
class TickMapEvents{
	/**
	 * HashMap for the mapping of the ticks and the MidiEvents
	 */
	private HashMap tickMap = new HashMap();
	
	/**
	 * Method to check if the TickMap does already contain the given tick.
	 * @param tick, tick to check
	 * @return true, if the TickMap does contain this tick
	 */
	boolean containsTick(final long i_tick){
		return tickMap.containsKey(new Long(i_tick));
	}
	
	/**
	 * Method to add a tick to the TickMap.
	 * @param tick, tick to add to the TickMap
	 */
	void addTick(final long i_tick){
		tickMap.put(new Long(i_tick),new Vector());
	}
	
	/**
	 * Method to get all MidiEvents set on a tick
	 * @param i_tick 
	 * @return EventList containing all the MidiEvents for the given tick
	 */
	Vector getEventsForTick(final long i_tick){
		return (Vector)tickMap.get(new Long(i_tick));
	}
	
	/**
	 * Method to add an Event to the TickMap
	 * @param event, event to be added
	 */
	void addEvent(
		final MidiEvent i_event,
		final long i_tick
	){
		if (!containsTick(i_tick)){
			addTick(i_tick);
		}
		getEventsForTick(i_tick).add(i_event);
	}
	
	/**
	 * Removes a MidiEvent from the TickMap.
	 * @param event, MidiEvent that has to be removed
	 */
	void removeEvent(
		final MidiEvent i_event,
		final long i_tick
	){
		getEventsForTick(i_tick).remove(i_event);
	}
	
	long getMaxTick(){
		long result = 0;
		Object[] ticks = tickMap.keySet().toArray();
		for(int i = 0; i < ticks.length; i++){
			result = Math.max(result,((Long)ticks[i]).longValue());
		}
		return result;
	}
}
/*
Part of the proMIDI lib - http://texone.org/promidi

Copyright (c) 2005 Christian Riekoff

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General
Public License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA  02111-1307  USA
*/

package promidi;

import java.util.Comparator;
import java.util.TreeSet;

/**
 * The MidiOut class is for sending midi events. An MidiOut is
 * defined by a port and a midichannel. To get a MidiOut you have to use 
 * the getMidiOut() method of the MidiIO class.
 * @related MidiIO
 * @related Note
 * @related Controller
 * @related ProgramChange
 */
public class MidiOut{
	/**
	 * The midichannel of the midiout
	 */
	final int midiChannel;

	/**
	 * The midioutput port of the midiout
	 */
	final MidiOutDevice midiOutDevice;
	
	static private NoteBuffer noteBuffer;
	
	/**
	 * Initializes a new MidiOutput.
	 * @related MidiOut
	 * @example promidi_midiout
	 * @param midiChannel int, the midiChannel of the midiout
	 * @param midiOutDevice MidiOutPort, the midi port of the midiout
	 */
	MidiOut(final int midiChannel, final MidiOutDevice midiOutDevice){
		if(noteBuffer == null){
			noteBuffer = new NoteBuffer();
		}
		this.midiChannel = midiChannel;
		this.midiOutDevice = midiOutDevice;
	}

	/**
	 * Looks if two MidiOuts are equal. This is the case if they have
	 * the same midiChannel and port.
	 * @return true, if the given object is equal to the MidiOut
	 * @shortdesc Looks if two MidiOuts are equal.
	 */
	public boolean equals(final Object object){
		if(!(object instanceof MidiOutDevice))return false;
		final MidiOut midiOut = (MidiOut)object;
		if(midiChannel != midiOut.midiChannel) return false;
		if(!(midiOutDevice.equals(midiOut.midiOutDevice))) return false;
		return true;
	}
	
	/**
	 * @invisible
	 * @param i_event
	 * @throws InvalidMidiDataException
	 */
	public void sendEvent(final MidiEvent i_event){
		if (i_event.getChannel() > 15 || i_event.getChannel() < 0){
			throw new InvalidMidiDataException("You tried to send to midi channel" + i_event.getChannel() + ". With midi you only have the channels 0 - 15 available.");
		}
		i_event.setChannel(midiChannel);
		midiOutDevice.sendEvent(i_event);
	}
	
	/**
	 * Packs the given data to a midi event and sends it to the tracks midi out.
	 * @param i_command
	 * @param i_data1
	 * @param i_data2
	 */
	void sendEvent(final int i_command, final int i_data1, final int i_data2){
		final MidiEvent event = new MidiEvent(i_command, i_data1, i_data2);
		sendEvent(event);
	}

	/**
	 * Use this method to send a control change to the midioutput. You can send 
	 * control changes to change the sound on midi sound sources for example.
	 * @param controller Controller, the controller you want to send.
	 * @example promidi_midiout
	 * @shortdesc Use this method to send a control change to the midioutput.
	 * @related MidiOut
	 * @related Controller
	 * @related sendNote ( )
	 * @related sendProgramChange ( )
	 */
	public void sendController(Controller controller){
		try{
			sendEvent(controller);
		}catch (InvalidMidiDataException e){
			if (controller.getNumber() > 127 || controller.getNumber() < 0){
				throw new RuntimeException("You tried to send the controller number " + controller.getNumber()
					+ ". With midi you only have the controller numbers 0 - 127 available.");
			}
			if (controller.getValue() > 127 || controller.getValue() < 0){
				throw new RuntimeException("You tried to send the controller value " + controller.getValue()
					+ ". With midi you only have the controller values 0 - 127 available.");
			}
		}
	}

	/**
	 * With this method you can send a note on to your midi output. You can send note on commands
	 * to trigger midi soundsources. Be aware that you have to take care to send note off commands
	 * to release the notes otherwise you get midi hang ons.
	 * @param i_note Note, the note you want to send the note on for
	 * @example promidi_midiout
	 * @shortdesc With this method you can send a note on to your midi output.
	 * @related MidiOut
	 * @related Note
	 * @related sendController ( )
	 * @related sendProgramChange ( )
	 */
	public void sendNote(final Note i_note){
		try{
			sendEvent(i_note);
			noteBuffer.addNote(this,i_note);
		}catch (InvalidMidiDataException e){
			if (i_note.getPitch() > 127 || i_note.getPitch() < 0){
				throw new RuntimeException("You tried to send a note with the pitch " + i_note.getPitch() + ". With midi you only have pitch values from 0 - 127 available.");
			}
			if (i_note.getVelocity() > 127 || i_note.getVelocity() < 0){
				throw new RuntimeException("You tried to send a note with the velocity " + i_note.getVelocity()
					+ ". With midi you only have velocities values from 0 - 127 available.");
			}
		}
	}

	/**
	 * With this method you can send program changes to your midi output. Program changes are used 
	 * to change the preset on a midi sound source.
	 * @param i_programChange ProgramChange, program change you want to send
	 * @example promidi_midiout
	 * @shortdesc With this method you can send program changes to your midi output.
	 * @related MidiOut
	 * @related ProgramChange
	 * @related sendController ( )
	 * @related sendNote ( )
	 */
	public void sendProgramChange(final ProgramChange i_programChange){
		try{
			sendEvent(i_programChange);
		}catch (InvalidMidiDataException e){
			if (i_programChange.getNumber() > 127 || i_programChange.getNumber() < 0){
				throw new RuntimeException("You tried to send the program number " + i_programChange.getNumber()
					+ ". With midi you only have the program numbers 0 - 127 available.");
			}
		}
	}
	
	/**
	 * A Comparator defining how CueNote objects have to be sorted. According
	 * to there length
	 * @author christianr
	 *
	 */
	private static class NoteComparator implements Comparator{
		public int compare(final Object i_obj1, final Object i_obj2){
			final CueNote note1 = (CueNote)i_obj1;
			final CueNote note2 = (CueNote)i_obj2;
			return (int)(note1.offTime - note2.offTime);
		}
	}
	
	/**
	 * Class for saving all necessary information for buffering and
	 * and sending a note off command coressponding to a send note on.
	 * @author christianr
	 *
	 */
	private static class CueNote extends MidiEvent{
		/**
		 * The midiout the note has to be send out
		 */
		final MidiOut midiOut;
		
		/**
		 * the time the note off event has to be send
		 */
		final long offTime;
		
		CueNote(final MidiOut i_midiOut,final Note note, final long i_offTime){
			super(NOTE_OFF,note.getPitch(),note.getVelocity());
			midiOut = i_midiOut;
			offTime =i_offTime;
		}
		
		/**
		 * triggers the note off
		 *
		 */
		void trigger(){
			try{
				midiOut.sendEvent(this);
			}catch (InvalidMidiDataException e){
				e.printStackTrace();
			}
		}
	}
	
	/**
	 * NoteBuffer is a simultaniously running thread buffering all
	 * note off events. All events are events are buffered and send
	 * according to the note length.
	 * @author christianr
	 *
	 */
	private static class NoteBuffer extends Thread{
		
		/**
		 * number of times the thread has been looped
		 */
		private long numberOfLoops = 0;
		
		/**
		 * Set that automatically sort all incoming notes according
		 * there length
		 */
		private final TreeSet notes = new TreeSet(new NoteComparator());
		
		/**
		 * Initializes a new NoteBuffer by starting the thread
		 */
		NoteBuffer(){
			this.start();
		}
		
		/**
		 * Here all current note off events are send and deleted afterwards
		 */
		public void run(){
			while (true){
				numberOfLoops++;
				try{
					Thread.sleep(1);

					final Object[] cueNotes = notes.toArray();
					int counter = 0;

						while (
							counter < cueNotes.length && 
							cueNotes.length > 0 && 
							((CueNote) cueNotes[counter]).offTime <= numberOfLoops
						){
							CueNote note = ((CueNote) cueNotes[counter]);
							note.trigger();
							notes.remove(note);
							counter++;
						}
					
				}catch (InterruptedException e){
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
		}
		
		/**
		 * Adds an note off event to the buffer
		 * @param i_midiOut
		 * @param i_note
		 */
		void addNote(final MidiOut i_midiOut, final Note i_note){
			notes.add(new CueNote(i_midiOut, i_note, i_note.getNoteLength()+numberOfLoops));
		}
	}
}
/*
Part of the proMIDI lib - http://texone.org/promidi

Copyright (c) 2005 Christian Riekoff

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General
Public License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA  02111-1307  USA
*/

/**
 * Must be in the javax.sound.midi package because the constructor is package-private
 */
package promidi;

/**
 * A track handles all midiEvents of a song for a certain midiout. You can directly 
 * add Events like Notes or ControllerChanges to it or also work with patterns.
 * @example promidi_sequencer
 * @related Song
 * @related Sequencer
 * @related Pattern
 */
public class Track extends Pattern{

	/**
	 * The midiOutput of the Track
	 */
	private MidiOut midiOut;
	
	/**
	 * Song the track is added to
	 */
	private Song song;

	/**
	 * Creates a new track using the given name and MidiOut
	 * @param i_name String: name for the track
	 * @param i_midiOut MidiOut: midi out the events are send to
	 * @example promidi_sequencer
	 * @related MidiOut
	 */
	public Track(final String i_name, final MidiOut i_midiOut){
		super(i_name,0);
		midiOut = i_midiOut;
	}

	/**
	 * Sends a note off to all 128 midi notes. 
	 * @param i_doControllers, if true also the controller data is set to 0
	 */
	void sendMidiPanic(final boolean i_doControllers){
		for (int data1 = 0; data1 < 128; data1++){
			midiOut.sendEvent(MidiEvent.NOTE_OFF, data1, 0);
		}

		/* reset all controllers */
		if (i_doControllers){
			for (int data1 = 0; data1 < 128; data1++){
				midiOut.sendEvent(MidiEvent.CONTROL_CHANGE, data1, 0);
			}
		}
	}
	
	/**
	 * Resets the midi controllers at the given tick. THis method is called 
	 * by the sequencer when looping a sequence, or when starting playback in 
	 * the middle of the song.
	 * @param i_tick
	 */
	void resetControllers(
		final long i_tick
	){
		resetControllers(i_tick,midiOut);
	}
	
	/**
	 * Used by the sequencer to play the events for the given tick.
	 * @param tick ,thats MidiEvents has to be returned
	 */
	void sendEventsForTick(
		final long i_tick
	){
		sendEventsForTick(i_tick,midiOut);
	}
	
	/**
	 * Returns the song the track was added to
	 * @return
	 */
	Song getSong(){
		return song;
	}
	
	/**
	 * Set the song the track was added to
	 * @param i_song
	 */
	void setSong(final Song i_song){
		song = i_song;
	}

	/**
	 * Returns the MidiOutput of the track.
	 * @return MidiOut, the Midi Output of the track
	 * @related Track
	 */
	public MidiOut getMidiOut(){
		return midiOut;
	}

	/**
	 * Sets the MidiOut of the Track
	 * @param midiOut MidiOut, the new MidiOutput of the track
	 * @related Track
	 */
	public void setMidiOut(final MidiOut i_midiOut){
		midiOut = i_midiOut;
	}
}
/*
 Part of the proMIDI lib - http://texone.org/promidi

 Copyright (c) 2005 Christian Riekoff

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General
 Public License along with this library; if not, write to the
 Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 Boston, MA  02111-1307  USA
 */

package promidi;

import javax.sound.midi.MidiUnavailableException;
import javax.sound.midi.Receiver;

/**
 * This class has no accessable contructor use MidiIO.openOutput() to get a MidiOut. 
 * MidiOut is the direct connection to one of your midi out ports. You can use different  
 * methods to send notes, control and program changes through one midi out port.
 * @example promidi_midiout
 * @related MidiIO
 * @related Note
 * @related Controller
 * @related ProgramChange
 */
class MidiOutDevice extends MidiDevice{

	private final Receiver outputReceiver;

	MidiOutDevice(
		final javax.sound.midi.MidiDevice midiDevice,
		final int deviceNumber
	) throws MidiUnavailableException{
		super(midiDevice,deviceNumber);
		outputReceiver = midiDevice.getReceiver();
	}

	/**
	 * @param event
	 * @throws InvalidMidiDataException
	 */
	public void sendEvent(final MidiEvent event){
		if (event.getChannel() > 15 || event.getChannel() < 0){
			throw new InvalidMidiDataException("You tried to send to midi channel" + event.getChannel() + ". With midi you only have the channels 0 - 15 available.");
		}
		outputReceiver.send(event, -1);
	}

	/**
	 * Use this method to send a control change to the midioutput. You can send 
	 * control changes to change the sound on midi sound sources for example.
	 * @param controller Controller, the controller you want to send.
	 * @example promidi_midiout
	 * @shortdesc Use this method to send a control change to the midioutput.
	 * @related Controller
	 * @related sendNoteOn ( )
	 * @related sendNoteOff ( )
	 * @related sendProgramChange ( )
	 */
	public void sendController(Controller controller){
		try{
			sendEvent(controller);
		}catch (InvalidMidiDataException e){
			if (controller.getNumber() > 127 || controller.getNumber() < 0){
				throw new InvalidMidiDataException("You tried to send the controller number " + controller.getNumber()
					+ ". With midi you only have the controller numbers 0 - 127 available.");
			}
			if (controller.getValue() > 127 || controller.getValue() < 0){
				throw new InvalidMidiDataException("You tried to send the controller value " + controller.getValue()
					+ ". With midi you only have the controller values 0 - 127 available.");
			}
		}
	}

	/**
	 * With this method you can send a note on to your midi output. You can send note on commands
	 * to trigger midi soundsources. Be aware that you have to take care to send note off commands
	 * to release the notes otherwise you get midi hang ons.
	 * @param note Note, the note you want to send the note on for
	 * @example promidi_midiout
	 * @shortdesc With this method you can send a note on to your midi output.
	 * @related Note
	 * @related sendController ( )
	 * @related sendNoteOff ( )
	 * @related sendProgramChange ( )
	 */
	public void sendNoteOn(Note note){
		try{
			sendEvent(note);
		}catch (InvalidMidiDataException e){
			if (note.getPitch() > 127 || note.getPitch() < 0){
				throw new InvalidMidiDataException("You tried to send a note with the pitch " + note.getPitch() + ". With midi you only have pitch values from 0 - 127 available.");
			}
			if (note.getVelocity() > 127 || note.getVelocity() < 0){
				throw new InvalidMidiDataException("You tried to send a note with the velocity " + note.getVelocity()
					+ ". With midi you only have velocities values from 0 - 127 available.");
			}
		}
	}

	/**
	 * Use this method to send a note off command to your midi output. You have to send note off commands 
	 * to release send note on commands.
	 * @param note Note, the note you want to send the note off for
	 * @example promidi_midiout
	 * @shortdesc Use this method to send a note off command to your midi output.
	 * @related Note
	 * @related sendController ( )
	 * @related sendNoteOn ( )
	 * @related sendProgramChange ( )
	 */
	public void sendNoteOff(Note note){
		note.setToNoteOff();
		sendNoteOn(note);
	}

	/**
	 * With this method you can send program changes to your midi output. Program changes are used 
	 * to change the preset on a midi sound source.
	 * @param programChange ProgramChange, program change you want to send
	 * @example promidi_midiout
	 * @shortdesc With this method you can send program changes to your midi output.
	 * @related Note
	 * @related sendController ( )
	 * @related sendNoteOn ( )
	 * @related sendNoteOff ( )
	 */
	public void sendProgramChange(ProgramChange programChange){
		try{
			sendEvent(programChange);
		}catch (InvalidMidiDataException e){
			if (programChange.getNumber() > 127 || programChange.getNumber() < 0){
				throw new InvalidMidiDataException("You tried to send the program number " + programChange.getNumber()
					+ ". With midi you only have the program numbers 0 - 127 available.");
			}
		}
	}
}
/*
Part of the proMIDI lib - http://texone.org/promidi

Copyright (c) 2005 Christian Riekoff

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General
Public License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA  02111-1307  USA
*/

package promidi;

/**
 * This exception is thrown when you want to access an unavailable Midi port.
 * @nosuperclasses
 * @invisible
 */
public class UnavailablePortException extends IllegalArgumentException{
	static final long serialVersionUID = 0;
	UnavailablePortException(String message){
		super(message);
	}
}
/*
Part of the proMIDI lib - http://texone.org/promidi

Copyright (c) 2005 Christian Riekoff

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General
Public License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA  02111-1307  USA
*/

package promidi;

import javax.sound.midi.InvalidMidiDataException;
import javax.sound.midi.ShortMessage;

/**
 * Note represents a midi note. It has a midi port, a midi channel, 
 * a pitch and a velocity. You can receive Notes from midi inputs and send 
 * them to midi outputs. 
 * @example promidi_midiout
 * @nosuperclasses
 * @related Controller
 * @related ProgramChange
 * @related MidiIO
 */
public class Note extends MidiEvent{
	private int command = ShortMessage.NOTE_ON;
	
	/**
	 * the length of the note in milliSeconds
	 */
	private int length;
	
	/**
	 * Inititalizes a new Note object. You can build a Note to send it to 
	 * a midi output. Be aware that different from the old promidi version
	 * you do not have to send the note off seperatly, instead you provide a
	 * length on initializing the node and promidi automatically sends the
	 * according note off.<br>
	 * @example promidi_midiout;
	 * @param i_pitch int, pitch of a note
	 * @param i_velocity int, velocity of a note
	 * @param i_length int, length of the note in milliseconds
	 */
	public Note(final int i_pitch, final int i_velocity, final int i_length){
		super(NOTE_ON,i_pitch,i_velocity);
		length = i_length;
	}
	
	Note(final int i_pitch, final int i_velocity){
		this(i_pitch, i_velocity,0);
	}
	
	/**
	 * Initialises a new Note from a java ShortMessage
	 * @param shortMessage
	 * @invisible
	 */
	Note(final ShortMessage shortMessage){
		super(shortMessage);
		length = 0;
	}
	
	/**
	 * Use this method to get the pitch of a note.
	 * @return int, the pitch of a note
	 * @example promidi
	 * @related Note
	 * @related setPitch ( )
	 * @related getVelocity ( )
	 * @related setVelocity ( )
	 */
	public int getPitch(){
		return getData1();
	}
	
	/**
	 * Use this method to set the pitch of a note
	 * @param pitch int, new pitch for the note
	 * @related Note
	 * @related getPitch ( )
	 * @related getVelocity ( )
	 * @related setVelocity ( )
	 */
    public void setPitch(final int i_pitch){
		setData1(i_pitch);
    }
    
	/**
	 * Use this method to get the velocity of a note.
	 * @return int, the velocity of a note
	 * @example promidi
	 * @related Note
	 * @related setVelocity ( )
	 * @related getPitch ( )
	 * @related setPitch ( )
	 */
	public int getVelocity(){
		return getData2();
	}
	
	/**
	 * Use this method to set the velocity of a note.
	 * @param velocity int, new velocity for the note
	 * @related Note
	 * @related getVelocity ( )
	 * @related getPitch ( )
	 * @related setPitch ( )
	 */
    public void setVelocity(final int i_velocity){
		setData2(i_velocity);
    }
    
    /**
     * Returns the length of the note in milliseconds
     * @return int: the length of the note
     * @related Note
     */
    public int getNoteLength(){
   	 return length;
    }
    
    /**
     * Sets the length of the note
     * @param i_length int: new length of the note
     * @related Note
     * @related setPitch ( )
     * @related setVelocity ( )
     */
    public void setLength(final int i_length){
   	 length = i_length;
    }
	
	/**
	 * Internal Method to set this note to send the note off command
	 */
	void setToNoteOff(){
		try{
			command=ShortMessage.NOTE_OFF;
			setMessage(command,getChannel(),getData1(),getData2());
		}catch (InvalidMidiDataException e){
			e.printStackTrace();
		}
	}
}
/*
/*
Part of the proMIDI lib - http://texone.org/promidi

Copyright (c) 2005 Christian Riekoff

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General
Public License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA  02111-1307  USA
*/

package promidi;

import java.util.Vector;

import javax.sound.midi.MidiMessage;
import javax.sound.midi.ShortMessage;

/**
 * A cache object to keep hold of notes that are currently on.
 */
class NoteOnCache{

	private Vector pendingNoteOffs = new Vector();

	NoteOnCache(){
		pendingNoteOffs.ensureCapacity(256);
	}

	void interceptMessage(MidiMessage msg){
		try{
			ShortMessage shm = (ShortMessage) msg;
			if (shm.getCommand() == ShortMessage.NOTE_ON){
				if (shm.getData2() == 0){
					pendingNoteOffs.remove(new Integer(shm.getChannel() << 8 | shm.getData1()));
				}else
					pendingNoteOffs.add(new Integer(shm.getChannel() << 8 | shm.getData1()));
			}
		}catch (Exception e){
		}
	}

	Vector getPendingNoteOffs(){
		return pendingNoteOffs;
	}

	void releasePendingNoteOffs(){
		pendingNoteOffs.clear();
	}
}
/*
Part of the proMIDI lib - http://texone.org/promidi

Copyright (c) 2005 Christian Riekoff

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General
Public License along with this library; if not, write to the
Free Software Foundation, Inc., 59 Temple Place, Suite 330,
Boston, MA  02111-1307  USA
*/

package promidi;
/**
 * Note this class is only needed for building the documentation of 
 * the methods that can be implemented in the processing app.
 */


/**
 * PApplet is your processing application. You can implement different 
 * methods to react on incoming midi messages. proMIDI is calling these 
 * methods on incoming midi data.<br>
 * You also use the plug function to forward midiInformation of your
 * choice to the desired object and method.
 * @example promidi_reflection
 * @related MidiIO
 * @related Note
 * @related Controller
 * @related ProgramChange 
 */
public class PApplet{
	
	/**
	 * The noteOn() function is called everytime a note on command comes through one 
	 * of your opened midi inputs. 
	 * @param note Note: the incoming note on
	 * @param deviceNumber int: the number of the device the note was send through
	 * @param midiChannel int: the midi channel the note was send through
	 * @related Note
	 * @related noteOff ( )
	 * @related controllerIn ( )
	 * @related programChange ( )
	 * @example promidi_reflection
	 */
	public void noteOn(
		final Note note,
		final int deviceNumber,
		final int midiChannel
	){
		
	}
	
	/**
	 * The noteOff() function is called everytime a note off command comes through one 
	 * of your opened midi inputs. 
	 * @param note Note, the incoming note off
	 * @param deviceNumber int: the number of the device the note was send through
	 * @param midiChannel int: the midi channel the note was send through
	 * @related Note
	 * @related noteOn ( )
	 * @related controllerIn ( )
	 * @related programChange ( )
	 * @example promidi_reflection
	 */
	public void noteOff(
		final Note note,
		final int deviceNumber,
		final int midiChannel
	){
		
	}
	
	/**
	 * The controllerIn() function is called everytime a control change command comes through one 
	 * of your opened midi inputs. 
	 * @param controller Controller, the incoming control change
	 * @param deviceNumber int: the number of the device the note was send through
	 * @param midiChannel int: the midi channel the note was send through
	 * @related Note
	 * @related noteOn ( )
	 * @related noteOff ( )
	 * @related programChange ( )
	 * @example promidi_reflection
	 */
	public void controllerIn(
		final Controller controller,
		final int deviceNumber,
		final int midiChannel
	){
		
	}
	
	/**
	 * The programChange() function is called everytime a program change command comes through one 
	 * of your opened midi inputs. 
	 * @param programChange ProgramChange: the incoming program change
	 * @param deviceNumber int: the number of the device the note was send through
	 * @param midiChannel int: the midi channel the note was send through
	 * @related Note
	 * @related noteOn ( )
	 * @related noteOff ( )
	 * @related controllerIn ( )
	 * @example promidi_reflection
	 */
	public void programChange(
		final ProgramChange programChange,
		final int deviceNumber,
		final int midiChannel
	){
		
	}
}
