namespace ProductExceptSelf
{
    internal class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Hello, World!");
        }
    }
    public class Solution
    {
        //Time: O(n)
        //Space: O(n)
        public int[] ProductExceptSelf(int[] nums)
        {
            int n = nums.Length;
            int[] result = new int[n];
            int leftProduct = 1;
            for (int i = 0; i < n; i++)
            {
                result[i] = leftProduct;
                leftProduct *= nums[i];
            }
            int rightProduct = 1;
            for (int i = n - 1; i >= 0; i--)
            {
                //هنا ضربنا علطول عشان نطلع العناصر مره واحده في لوب واحد
                result[i] *= rightProduct;
                rightProduct *= nums[i];
            }
            return result;
        }
    }
}
