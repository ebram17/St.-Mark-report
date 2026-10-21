// إعداد اتصال Supabase (تأكد من وضع بياناتك الصحيحة هنا)
const SUPABASE_URL = 'ضع_رابط_السูปابيس_هنا';
const SUPABASE_KEY = 'ضع_مفتاح_الـ_anon_key_هنا';
const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

async function saveSupervisor() {
    const fullName = document.getElementById('fullNameInput').value.trim();
    const email = document.getElementById('emailInput').value.trim();
    const branch = document.getElementById('branchSelect').value;
    const department = document.getElementById('departmentSelect').value;

    if (!fullName || !email) {
        alert('من فضلك ادخل الاسم والبريد الإلكتروني على الأقل');
        return;
    }

    try {
        // تحديث بيانات المشرف بالاعتماد على الإيميل مباشرة من غير UUID يدوي
        const { data, error } = await supabaseClient
            .from('profiles')
            .update({ 
                full_name: fullName, 
                branch: branch, 
                department: department,
                role: 'supervisor' 
            })
            .eq('email', email);

        if (error) throw error;

        alert('تم حفظ وتحديث بيانات المشرف بنجاح!');
        
        // تفريغ الحقول بعد الحفظ الناجح
        document.getElementById('fullNameInput').value = '';
        document.getElementById('emailInput').value = '';

    } catch (error) {
        alert('حدث خطأ أثناء الحفظ: ' + error.message);
    }
}
