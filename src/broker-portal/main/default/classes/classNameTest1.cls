public with sharing class classNameTest {
    public void method1() {
        // Large duplicated code block
        Integer a = 10;
        Integer b = 20;
        Integer c = a + b;
        System.debug(c);

        String str1 = 'Hello';
        String str2 = 'World';
        String result = str1 + ' ' + str2;
        System.debug(c);

        List<Integer> numbers = new List<Integer>{ 1, 2, 3 };
        Integer sum = 0;
        for (Integer num : numbers) {
            sum += num;
        }
    }
}
