/**
 * ANDES Lab - University of California, Merced
 * This class provides a simple list.
 *
 * @author UCM ANDES Lab
 * @author Alex Beltran
 * @date   2013/09/03
 * 
 */

interface List<t>{
   /**
    * Put value into the end of the list.
    *
    * @param input - data to be inserted
    */
   command void pushback(t input);
	command void pushfront(t input);
	command t remove(uint16_t position);
	command t popback();
	command t popfront();
	command t front();
	command t back();
	command bool isEmpty();
	command bool isFull();
	command uint16_t size();
	command t get(uint16_t position);
	command uint16_t maxSize();
	command void replace(uint8_t position, t input);

}
