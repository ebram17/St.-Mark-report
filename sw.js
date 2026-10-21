// دالة حفظ المشرف الجديدة بدون الحاجة للـ UUID اليدوي
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
        // البحث عن المستخدم في جدول الـ profiles أو ربطه بالبريد الإلكتروني مباشرة
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

        alert('تم حفظ بيانات المشرف بنجاح!');
        // إعادة تحميل أو تفريغ الحقول حسب الحاجة
    } catch (error) {
        alert('حدث خطأ أثناء الحفظ: ' + error.message);
    }
}
