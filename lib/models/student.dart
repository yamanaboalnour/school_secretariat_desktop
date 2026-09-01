class Student {
  const Student({
    this.id,
    this.generalId,
    this.nationalId,
    this.firstName,
    this.lastName,
    this.nickname,
    this.fullName,
    this.fatherName,
    this.motherName,
    this.gender,
    this.birthDate,
    this.mobile,
    this.currentGrade,
    this.currentSection,
    this.schoolEntryDate,
  });

  final int? id;
  final int? generalId;
  final String? nationalId;
  final String? firstName;
  final String? lastName;
  final String? nickname;
  final String? fullName;
  final String? fatherName;
  final String? motherName;
  final String? gender;
  final String? birthDate;
  final String? mobile;
  final String? currentGrade;
  final String? currentSection;
  final String? schoolEntryDate;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'general_id': generalId,
      'national_id': nationalId,
      'first_name': firstName,
      'last_name': lastName,
      'nickname': nickname,
      'full_name': fullName,
      'father_name': fatherName,
      'mother_name': motherName,
      'gender': gender,
      'birth_date': birthDate,
      'mobile': mobile,
      'current_grade': currentGrade,
      'current_section': currentSection,
      'school_entry_date': schoolEntryDate,
    };
  }

  factory Student.fromMap(Map<String, Object?> map) {
    return Student(
      id: map['id'] as int?,
      generalId: map['general_id'] as int?,
      nationalId: map['national_id'] as String?,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      nickname: map['nickname'] as String?,
      fullName: map['full_name'] as String?,
      fatherName: map['father_name'] as String?,
      motherName: map['mother_name'] as String?,
      gender: map['gender'] as String?,
      birthDate: map['birth_date'] as String?,
      mobile: map['mobile'] as String?,
      currentGrade: map['current_grade'] as String?,
      currentSection: map['current_section'] as String?,
      schoolEntryDate: map['school_entry_date'] as String?,
    );
  }
}
