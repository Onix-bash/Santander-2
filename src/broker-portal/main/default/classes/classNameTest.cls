/**
 * @created by Stanislav Grinko
 */

public with sharing class classNameTest {
 // test push commit

 public void duplicateMethod2() {
        // Duplicate code block
        for (Integer i = 0; i < 5; i++) {
            System.debug('Iteration: ' + i);
        }
    }

    public void duplicateMethod1() {
        // Duplicate code block
        for (Integer i = 0; i < 5; i++) {
            System.debug('Iteration: ' + i);
        }
    }

}
