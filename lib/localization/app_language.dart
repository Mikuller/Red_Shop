import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_shop/models/models.dart';

enum AppLanguage { english, amharic }

class AppLanguageProvider extends ChangeNotifier {
  AppLanguage _language;

  AppLanguageProvider({AppLanguage initialLanguage = AppLanguage.english})
    : _language = initialLanguage;

  AppLanguage get language => _language;
  AppLocalizer get strings => AppLocalizer(_language);

  void setLanguage(AppLanguage value) {
    if (_language == value) {
      return;
    }

    _language = value;
    notifyListeners();
  }
}

class AppLocalizer {
  final AppLanguage language;

  const AppLocalizer(this.language);

  static const Map<String, Map<AppLanguage, String>> _strings = {
    'appName': {
      AppLanguage.english: 'Red Computer',
      AppLanguage.amharic: 'Red Computer',
    },
    'language': {AppLanguage.english: 'Language', AppLanguage.amharic: 'ቋንቋ'},
    'english': {AppLanguage.english: 'English', AppLanguage.amharic: 'English'},
    'amharic': {AppLanguage.english: 'Amharic', AppLanguage.amharic: 'አማርኛ'},
    'preparingWorkspace': {
      AppLanguage.english: 'Getting things ready',
      AppLanguage.amharic: 'እየተዘጋጀ ነው',
    },
    'connectingFirebase': {
      AppLanguage.english: 'Connecting to Firebase and loading your account.',
      AppLanguage.amharic: 'ወደ Firebase በመገናኘት መለያዎን እየጫነ ነው።',
    },
    'loadingWorkspace': {
      AppLanguage.english: 'Loading your account',
      AppLanguage.amharic: 'መለያዎን እየጫነ ነው',
    },
    'checkingAccess': {
      AppLanguage.english: 'Checking your role and shop access.',
      AppLanguage.amharic: 'የእርስዎን ሚና እና የሱቅ ፍቃድ እየመረመረ ነው።',
    },
    'profileMissingTitle': {
      AppLanguage.english: 'Profile not found',
      AppLanguage.amharic: 'ፕሮፋይል አልተገኘም',
    },
    'profileMissingMessage': {
      AppLanguage.english:
          'Your login is there, but the shop profile is missing.',
      AppLanguage.amharic: 'የመግቢያ መለያዎ አለ፣ ግን የሱቅ ፕሮፋይል አልተገኘም።',
    },
    'signOut': {AppLanguage.english: 'Sign out', AppLanguage.amharic: 'ውጣ'},
    'accessDisabledTitle': {
      AppLanguage.english: 'Access is off',
      AppLanguage.amharic: 'መግቢያው ተዘግቷል',
    },
    'accessDisabledMessage': {
      AppLanguage.english:
          'This account was turned off by the owner. Please ask the owner.',
      AppLanguage.amharic: 'ይህ መለያ በባለቤቱ ተዘግቷል። እባክዎ ባለቤቱን ያነጋግሩ።',
    },
    'shopLogin': {
      AppLanguage.english: 'Shop login',
      AppLanguage.amharic: 'የሱቅ መግቢያ',
    },
    'login': {AppLanguage.english: 'Log in', AppLanguage.amharic: 'ግባ'},
    'email': {AppLanguage.english: 'Email', AppLanguage.amharic: 'ኢሜይል'},
    'password': {
      AppLanguage.english: 'Password',
      AppLanguage.amharic: 'የይለፍ ቃል',
    },
    'needValidEmail': {
      AppLanguage.english: 'Enter a valid email.',
      AppLanguage.amharic: 'ትክክለኛ ኢሜይል ያስገቡ።',
    },
    'enterPassword': {
      AppLanguage.english: 'Enter your password.',
      AppLanguage.amharic: 'የይለፍ ቃልዎን ያስገቡ።',
    },
    'forgotPassword': {
      AppLanguage.english: 'Forgot password?',
      AppLanguage.amharic: 'የይለፍ ቃል ረሱ?',
    },
    'enterEmailFirst': {
      AppLanguage.english: 'Enter your email first.',
      AppLanguage.amharic: 'መጀመሪያ ኢሜይልዎን ያስገቡ።',
    },
    'passwordResetSent': {
      AppLanguage.english: 'Password reset email sent to {email}.',
      AppLanguage.amharic: 'የይለፍ ቃል መቀየሪያ ኢሜይል ወደ {email} ተልኳል።',
    },
    'ownerSetupDone': {
      AppLanguage.english: 'Owner setup is already done.',
      AppLanguage.amharic: 'የባለቤት ቅንብር ተጠናቋል።',
    },
    'createFirstOwner': {
      AppLanguage.english: 'Create the first owner account',
      AppLanguage.amharic: 'የመጀመሪያውን ባለቤት መለያ ፍጠር',
    },
    'ownerSetup': {
      AppLanguage.english: 'Set up owner',
      AppLanguage.amharic: 'ባለቤት አቀናብር',
    },
    'ownerAlreadyConfiguredTitle': {
      AppLanguage.english: 'Owner is already set',
      AppLanguage.amharic: 'ባለቤት ቀድሞ ተቀናብሯል',
    },
    'ownerAlreadyConfiguredMessage': {
      AppLanguage.english: 'The shop already has an owner. Go back and log in.',
      AppLanguage.amharic: 'ሱቁ ቀድሞ ባለቤት አለው። ተመልሰው ይግቡ።',
    },
    'firstOwnerTitle': {
      AppLanguage.english: 'Create the first owner account',
      AppLanguage.amharic: 'የመጀመሪያውን ባለቤት መለያ ፍጠር',
    },
    'firstOwnerMessage': {
      AppLanguage.english:
          'This account will manage staff, stock, sales, and reports.',
      AppLanguage.amharic: 'ይህ መለያ ሰራተኞችን፣ እቃዎችን፣ ሽያጮችን እና ሪፖርቶችን ያስተዳድራል።',
    },
    'fullName': {
      AppLanguage.english: 'Full name',
      AppLanguage.amharic: 'ሙሉ ስም',
    },
    'enterName': {
      AppLanguage.english: 'Enter your name.',
      AppLanguage.amharic: 'ስምዎን ያስገቡ።',
    },
    'minPassword': {
      AppLanguage.english: 'Use at least 6 characters.',
      AppLanguage.amharic: 'ቢያንስ 6 ፊደላት ይጠቀሙ።',
    },
    'createOwnerAccount': {
      AppLanguage.english: 'Create owner account',
      AppLanguage.amharic: 'የባለቤት መለያ ፍጠር',
    },
    'ownerCreated': {
      AppLanguage.english: 'Owner account created.',
      AppLanguage.amharic: 'የባለቤት መለያ ተፈጥሯል።',
    },
    'ownerConsole': {
      AppLanguage.english: 'Owner home',
      AppLanguage.amharic: 'የባለቤት መነሻ',
    },
    'openPos': {
      AppLanguage.english: 'Open POS',
      AppLanguage.amharic: 'POS ክፈት',
    },
    'logout': {AppLanguage.english: 'Log out', AppLanguage.amharic: 'ውጣ'},
    'welcomeBack': {
      AppLanguage.english: 'Welcome back, {name}',
      AppLanguage.amharic: 'እንኳን ደህና መጡ፣ {name}',
    },
    'ownerFallbackName': {
      AppLanguage.english: 'Owner',
      AppLanguage.amharic: 'ባለቤት',
    },
    'todaySummary': {
      AppLanguage.english: 'Today: {count} sale(s) | {amount}',
      AppLanguage.amharic: 'ዛሬ: {count} ሽያጭ | {amount}',
    },
    'netProfit': {
      AppLanguage.english: 'Net profit',
      AppLanguage.amharic: 'የተጣራ ትርፍ',
    },
    'lowStock': {
      AppLanguage.english: 'Low stock',
      AppLanguage.amharic: 'ትንሽ የቀረ እቃ',
    },
    'restocks': {
      AppLanguage.english: 'Restocks',
      AppLanguage.amharic: 'እቃ መሙላት',
    },
    'tapToOpen': {
      AppLanguage.english: 'Tap to open',
      AppLanguage.amharic: 'ለመክፈት ይንኩ',
    },
    'moneyIn': {
      AppLanguage.english: 'Money in',
      AppLanguage.amharic: 'የገባ ገንዘብ',
    },
    'salesDone': {
      AppLanguage.english: '{count} sales done',
      AppLanguage.amharic: '{count} ሽያጮች ተጠናቀዋል',
    },
    'profit': {AppLanguage.english: 'Profit', AppLanguage.amharic: 'ትርፍ'},
    'beforeShopCosts': {
      AppLanguage.english: 'Before shop costs',
      AppLanguage.amharic: 'ከሱቅ ወጪ በፊት',
    },
    'costs': {AppLanguage.english: 'Costs', AppLanguage.amharic: 'ወጪ'},
    'shopCostsAndTakeouts': {
      AppLanguage.english: 'Shop costs + take-outs',
      AppLanguage.amharic: 'የሱቅ ወጪ + የተወሰደ ገንዘብ',
    },
    'stockValue': {
      AppLanguage.english: 'Stock value',
      AppLanguage.amharic: 'የእቃ ዋጋ',
    },
    'unitsInStockCount': {
      AppLanguage.english: '{count} items in stock',
      AppLanguage.amharic: '{count} እቃዎች በክምችት ውስጥ',
    },
    'quickActions': {
      AppLanguage.english: 'Quick actions',
      AppLanguage.amharic: 'ፈጣን ስራዎች',
    },
    'dockHome': {
      AppLanguage.english: 'Home',
      AppLanguage.amharic: 'መነሻ',
    },
    'dockStock': {
      AppLanguage.english: 'Stock',
      AppLanguage.amharic: 'እቃ',
    },
    'dockMore': {
      AppLanguage.english: 'More',
      AppLanguage.amharic: 'ተጨማሪ',
    },
    'inventory': {
      AppLanguage.english: 'Inventory',
      AppLanguage.amharic: 'እቃ ዝርዝር',
    },
    'inventoryShort': {
      AppLanguage.english: 'Products and stock',
      AppLanguage.amharic: 'እቃዎች እና ክምችት',
    },
    'restocking': {
      AppLanguage.english: 'Restocking',
      AppLanguage.amharic: 'እቃ መሙላት',
    },
    'recordPurchaseArrivals': {
      AppLanguage.english: 'Record new stock',
      AppLanguage.amharic: 'አዲስ እቃ መዝግብ',
    },
    'stockWorkspace': {
      AppLanguage.english: 'Stock workspace',
      AppLanguage.amharic: 'የእቃ መስሪያ',
    },
    'stockWorkspaceHint': {
      AppLanguage.english:
          'Open inventory or record a fresh restock from one place.',
      AppLanguage.amharic: 'እቃ ዝርዝርን ይክፈቱ ወይም አዲስ መሙላት ከአንድ ቦታ ይመዝግቡ።',
    },
    'pos': {AppLanguage.english: 'POS', AppLanguage.amharic: 'POS'},
    'startSale': {
      AppLanguage.english: 'Start a sale',
      AppLanguage.amharic: 'ሽያጭ ጀምር',
    },
    'expenses': {AppLanguage.english: 'Expenses', AppLanguage.amharic: 'ወጪዎች'},
    'fastMoney': {
      AppLanguage.english: 'Fast money',
      AppLanguage.amharic: 'ፈጣን ገቢ',
    },
    'fastMoneyHint': {
      AppLanguage.english:
          'Quickly record one-off product or service money here.',
      AppLanguage.amharic: 'የአንድ ጊዜ የእቃ ወይም የአገልግሎት ገቢን በፍጥነት ይመዝግቡ።',
    },
    'trackSpendAndWithdrawals': {
      AppLanguage.english: 'Track costs and take-outs',
      AppLanguage.amharic: 'ወጪና የተወሰደ ገንዘብ ተከታተል',
    },
    'reports': {AppLanguage.english: 'Reports', AppLanguage.amharic: 'ሪፖርቶች'},
    'reportRange': {
      AppLanguage.english: 'Report range',
      AppLanguage.amharic: 'የሪፖርት ጊዜ',
    },
    'all': {
      AppLanguage.english: 'All',
      AppLanguage.amharic: 'ሁሉም',
    },
    'incomeSource': {
      AppLanguage.english: 'Income source',
      AppLanguage.amharic: 'የገቢ ምንጭ',
    },
    'daily': {
      AppLanguage.english: 'Daily',
      AppLanguage.amharic: 'የቀን',
    },
    'weekly': {
      AppLanguage.english: 'Weekly',
      AppLanguage.amharic: 'የሳምንት',
    },
    'monthly': {
      AppLanguage.english: 'Monthly',
      AppLanguage.amharic: 'ወርሃዊ',
    },
    'customRange': {
      AppLanguage.english: 'Custom',
      AppLanguage.amharic: 'ልዩ',
    },
    'pickDates': {
      AppLanguage.english: 'Pick dates',
      AppLanguage.amharic: 'ቀን ምረጥ',
    },
    'noDataInRange': {
      AppLanguage.english:
          'No sales, purchases, or expenses were recorded in this range yet.',
      AppLanguage.amharic: 'በዚህ ጊዜ ውስጥ ሽያጭ፣ ግዢ ወይም ወጪ ገና አልተመዘገበም።',
    },
    'vsPreviousPeriod': {
      AppLanguage.english: 'Vs previous: {value}',
      AppLanguage.amharic: 'ከቀደም ጊዜ ጋር: {value}',
    },
    'periodSummary': {
      AppLanguage.english: 'Period summary',
      AppLanguage.amharic: 'የጊዜ ማጠቃለያ',
    },
    'incomeSourceSummary': {
      AppLanguage.english: 'Source summary',
      AppLanguage.amharic: 'የምንጭ ማጠቃለያ',
    },
    'incomeEntries': {
      AppLanguage.english: 'Income entries',
      AppLanguage.amharic: 'የገቢ መዝገቦች',
    },
    'salesCountLabel': {
      AppLanguage.english: 'Sales made',
      AppLanguage.amharic: 'የተደረጉ ሽያጮች',
    },
    'purchaseCountLabel': {
      AppLanguage.english: 'Restocks logged',
      AppLanguage.amharic: 'የተመዘገቡ መሙላቶች',
    },
    'expenseCountLabel': {
      AppLanguage.english: 'Expense records',
      AppLanguage.amharic: 'የወጪ መዝገቦች',
    },
    'serviceCountLabel': {
      AppLanguage.english: 'Service jobs',
      AppLanguage.amharic: 'የአገልግሎት ስራዎች',
    },
    'fastMoneySalesLabel': {
      AppLanguage.english: 'Fast money sales',
      AppLanguage.amharic: 'የፈጣን ገቢ ሽያጮች',
    },
    'serviceChargeTotal': {
      AppLanguage.english: 'Service charges',
      AppLanguage.amharic: 'የአገልግሎት ክፍያዎች',
    },
    'paidServiceIncome': {
      AppLanguage.english: 'Paid service income',
      AppLanguage.amharic: 'የተከፈለ የአገልግሎት ገቢ',
    },
    'unpaidServiceIncome': {
      AppLanguage.english: 'Unpaid service income',
      AppLanguage.amharic: 'ያልተከፈለ የአገልግሎት ገቢ',
    },
    'unitsSold': {
      AppLanguage.english: 'Units sold',
      AppLanguage.amharic: 'የተሸጡ እቃዎች',
    },
    'expenseBreakdown': {
      AppLanguage.english: 'Expense breakdown',
      AppLanguage.amharic: 'የወጪ ዝርዝር',
    },
    'expenseEntriesCount': {
      AppLanguage.english: '{count} entries',
      AppLanguage.amharic: '{count} መዝገቦች',
    },
    'profitAndBestSellers': {
      AppLanguage.english: 'Profit and top items',
      AppLanguage.amharic: 'ትርፍ እና ብዙ የሚሸጡ እቃዎች',
    },
    'staff': {AppLanguage.english: 'Staff', AppLanguage.amharic: 'ሰራተኞች'},
    'createManageAccess': {
      AppLanguage.english: 'Create and manage access',
      AppLanguage.amharic: 'መለያ ፍጠር እና አስተዳድር',
    },
    'moreActions': {
      AppLanguage.english: 'More actions',
      AppLanguage.amharic: 'ተጨማሪ እርምጃዎች',
    },
    'safeSignOutHint': {
      AppLanguage.english: 'Leave this account safely when the shift is done.',
      AppLanguage.amharic: 'ሺፍቱ ሲያልቅ ከዚህ መለያ በደህና ውጡ።',
    },
    'topSellers': {
      AppLanguage.english: 'Top sellers',
      AppLanguage.amharic: 'ብዙ የሚሸጡ',
    },
    'topSellersEmpty': {
      AppLanguage.english: 'Your best-selling products will show here.',
      AppLanguage.amharic: 'ብዙ የሚሸጡ እቃዎችዎ እዚህ ይታያሉ።',
    },
    'revenueProfitLine': {
      AppLanguage.english: '{revenue} in | {profit} profit',
      AppLanguage.amharic: '{revenue} ገቢ | {profit} ትርፍ',
    },
    'lowStockWatch': {
      AppLanguage.english: 'Low stock watch',
      AppLanguage.amharic: 'ዝቅተኛ ክምችት',
    },
    'allStockOkay': {
      AppLanguage.english: 'All items are above the low-stock limit.',
      AppLanguage.amharic: 'ሁሉም እቃዎች ከዝቅተኛ ገደብ በላይ ናቸው።',
    },
    'thresholdOnly': {
      AppLanguage.english: 'Limit {count}',
      AppLanguage.amharic: 'ገደብ {count}',
    },
    'thresholdWithCategory': {
      AppLanguage.english: '{category} | Limit {count}',
      AppLanguage.amharic: '{category} | ገደብ {count}',
    },
    'grossProfit': {
      AppLanguage.english: 'Gross profit',
      AppLanguage.amharic: 'ጠቅላላ ትርፍ',
    },
    'revenueMinusCost': {
      AppLanguage.english: 'Money in minus item cost',
      AppLanguage.amharic: 'ገቢ ከእቃ ዋጋ በኋላ',
    },
    'afterExpensesAndWithdrawals': {
      AppLanguage.english: 'After costs and take-outs',
      AppLanguage.amharic: 'ከወጪና ከተወሰደ ገንዘብ በኋላ',
    },
    'restockSpend': {
      AppLanguage.english: 'Restock spend',
      AppLanguage.amharic: 'የመሙላት ወጪ',
    },
    'purchaseRecords': {
      AppLanguage.english: '{count} purchase records',
      AppLanguage.amharic: '{count} የግዢ መዝገቦች',
    },
    'operatingExpenses': {
      AppLanguage.english: 'Running costs',
      AppLanguage.amharic: 'የስራ ወጪ',
    },
    'withdrawalAmount': {
      AppLanguage.english: '{amount} take-outs',
      AppLanguage.amharic: '{amount} የተወሰደ ገንዘብ',
    },
    'bestSellingItems': {
      AppLanguage.english: 'Best-selling items',
      AppLanguage.amharic: 'ብዙ የሚሸጡ እቃዎች',
    },
    'topPerformersEmpty': {
      AppLanguage.english: 'Top items will show here after more sales.',
      AppLanguage.amharic: 'ብዙ የሚሸጡ እቃዎች ከተጨማሪ ሽያጭ በኋላ እዚህ ይታያሉ።',
    },
    'pcs': {AppLanguage.english: 'pcs', AppLanguage.amharic: 'ቁ'},
    'recentIncomeActivity': {
      AppLanguage.english: 'Recent income activity',
      AppLanguage.amharic: 'የቅርብ የገቢ እንቅስቃሴ',
    },
    'recentSales': {
      AppLanguage.english: 'Recent sales',
      AppLanguage.amharic: 'የቅርብ ሽያጮች',
    },
    'noIncomeActivityYet': {
      AppLanguage.english: 'No activity for this source yet.',
      AppLanguage.amharic: 'ለዚህ ምንጭ ገና እንቅስቃሴ የለም።',
    },
    'noSalesYet': {
      AppLanguage.english: 'No sales yet.',
      AppLanguage.amharic: 'ገና ሽያጭ የለም።',
    },
    'saleFallback': {AppLanguage.english: 'Sale', AppLanguage.amharic: 'ሽያጭ'},
    'recentExpenses': {
      AppLanguage.english: 'Recent expenses',
      AppLanguage.amharic: 'የቅርብ ወጪዎች',
    },
    'noExpensesYet': {
      AppLanguage.english: 'No expenses yet.',
      AppLanguage.amharic: 'ገና ወጪ የለም።',
    },
    'recentRestocks': {
      AppLanguage.english: 'Recent restocks',
      AppLanguage.amharic: 'የቅርብ መሙላቶች',
    },
    'noRestockYet': {
      AppLanguage.english: 'No restock history yet.',
      AppLanguage.amharic: 'ገና የመሙላት ታሪክ የለም።',
    },
    'purchaseLabel': {
      AppLanguage.english: 'Purchase',
      AppLanguage.amharic: 'ግዢ',
    },
    'itemLines': {
      AppLanguage.english: '{count} item lines',
      AppLanguage.amharic: '{count} የእቃ መስመሮች',
    },
    'addProduct': {
      AppLanguage.english: 'Add product',
      AppLanguage.amharic: 'እቃ ጨምር',
    },
    'editProduct': {
      AppLanguage.english: 'Edit product',
      AppLanguage.amharic: 'እቃ አርትዕ',
    },
    'name': {AppLanguage.english: 'Name', AppLanguage.amharic: 'ስም'},
    'nameRequired': {
      AppLanguage.english: 'Name is required.',
      AppLanguage.amharic: 'ስም ያስፈልጋል።',
    },
    'category': {AppLanguage.english: 'Category', AppLanguage.amharic: 'ምድብ'},
    'chooseCategory': {
      AppLanguage.english: 'Choose a category',
      AppLanguage.amharic: 'ምድብ ይምረጡ',
    },
    'addCategory': {
      AppLanguage.english: 'Add category',
      AppLanguage.amharic: 'ምድብ ጨምር',
    },
    'saveCategory': {
      AppLanguage.english: 'Save category',
      AppLanguage.amharic: 'ምድብ አስቀምጥ',
    },
    'clearCategory': {
      AppLanguage.english: 'Clear category',
      AppLanguage.amharic: 'ምድብ አጥፋ',
    },
    'categoryRequired': {
      AppLanguage.english: 'Enter a category name.',
      AppLanguage.amharic: 'የምድብ ስም ያስገቡ።',
    },
    'categoryOptional': {
      AppLanguage.english: 'You can leave this empty if needed.',
      AppLanguage.amharic: 'ካስፈለገ ባዶ መተው ይችላሉ።',
    },
    'categorySelected': {
      AppLanguage.english: 'Selected category: {name}',
      AppLanguage.amharic: 'የተመረጠው ምድብ: {name}',
    },
    'sku': {AppLanguage.english: 'SKU', AppLanguage.amharic: 'SKU'},
    'suggestedSellingPrice': {
      AppLanguage.english: 'Suggested selling price',
      AppLanguage.amharic: 'የተመከረ የሽያጭ ዋጋ',
    },
    'validPrice': {
      AppLanguage.english: 'Enter a valid price.',
      AppLanguage.amharic: 'ትክክለኛ ዋጋ ያስገቡ።',
    },
    'lowStockThreshold': {
      AppLanguage.english: 'Low stock limit',
      AppLanguage.amharic: 'ዝቅተኛ ክምችት ገደብ',
    },
    'validThreshold': {
      AppLanguage.english: 'Enter a valid limit.',
      AppLanguage.amharic: 'ትክክለኛ ገደብ ያስገቡ።',
    },
    'openingStock': {
      AppLanguage.english: 'Opening stock',
      AppLanguage.amharic: 'መነሻ ክምችት',
    },
    'openingUnitCost': {
      AppLanguage.english: 'Opening unit cost',
      AppLanguage.amharic: 'መነሻ የአንዱ ዋጋ',
    },
    'description': {
      AppLanguage.english: 'Description',
      AppLanguage.amharic: 'መግለጫ',
    },
    'imageUrl': {
      AppLanguage.english: 'Image URL',
      AppLanguage.amharic: 'የምስል URL',
    },
    'saveProduct': {
      AppLanguage.english: 'Save product',
      AppLanguage.amharic: 'እቃ አስቀምጥ',
    },
    'saveChanges': {
      AppLanguage.english: 'Save changes',
      AppLanguage.amharic: 'ለውጦችን አስቀምጥ',
    },
    'productAdded': {
      AppLanguage.english: 'Product added.',
      AppLanguage.amharic: 'እቃው ተጨምሯል።',
    },
    'productUpdated': {
      AppLanguage.english: 'Product updated.',
      AppLanguage.amharic: 'እቃው ታድሷል።',
    },
    'deleteProduct': {
      AppLanguage.english: 'Delete product',
      AppLanguage.amharic: 'እቃ ሰርዝ',
    },
    'deleteProductMessage': {
      AppLanguage.english: 'Delete {name}? This works only when stock is zero.',
      AppLanguage.amharic: '{name} ልትሰርዝ? ይህ የሚሰራው ክምችቱ 0 ሲሆን ብቻ ነው።',
    },
    'cancel': {AppLanguage.english: 'Cancel', AppLanguage.amharic: 'ሰርዝ'},
    'delete': {AppLanguage.english: 'Delete', AppLanguage.amharic: 'ሰርዝ'},
    'productDeleted': {
      AppLanguage.english: 'Product deleted.',
      AppLanguage.amharic: 'እቃው ተሰርዟል።',
    },
    'searchProducts': {
      AppLanguage.english: 'Search by name, category, or SKU',
      AppLanguage.amharic: 'በስም፣ በምድብ ወይም በSKU ፈልግ',
    },
    'allCategories': {
      AppLanguage.english: 'All categories',
      AppLanguage.amharic: 'ሁሉም ምድቦች',
    },
    'lowStockOnly': {
      AppLanguage.english: 'Low stock only',
      AppLanguage.amharic: 'ዝቅተኛ ክምችት ብቻ',
    },
    'productCount': {
      AppLanguage.english: '{count} products',
      AppLanguage.amharic: '{count} እቃዎች',
    },
    'unitsInStock': {
      AppLanguage.english: 'Units in stock',
      AppLanguage.amharic: 'በክምችት ያሉ',
    },
    'noProductsYet': {
      AppLanguage.english: 'No products yet',
      AppLanguage.amharic: 'ገና እቃ የለም',
    },
    'noFilterMatch': {
      AppLanguage.english: 'Nothing matched',
      AppLanguage.amharic: 'የተመሳሰለ አልተገኘም',
    },
    'createFirstProduct': {
      AppLanguage.english: 'Add your first product and start building stock.',
      AppLanguage.amharic: 'የመጀመሪያ እቃዎን ጨምሩ እና ክምችት ይጀምሩ።',
    },
    'tryDifferentSearch': {
      AppLanguage.english: 'Try another search or remove the low-stock filter.',
      AppLanguage.amharic: 'ሌላ ፍለጋ ይሞክሩ ወይም ማጣሪያውን ያጥፉ።',
    },
    'edit': {AppLanguage.english: 'Edit', AppLanguage.amharic: 'አርትዕ'},
    'restock': {AppLanguage.english: 'Restock', AppLanguage.amharic: 'ሙላ'},
    'uncategorized': {
      AppLanguage.english: 'No category',
      AppLanguage.amharic: 'ምድብ የለውም',
    },
    'cost': {
      AppLanguage.english: 'Cost {amount}',
      AppLanguage.amharic: 'ወጪ {amount}',
    },
    'suggested': {
      AppLanguage.english: 'Suggested {amount}',
      AppLanguage.amharic: 'የተመከረ {amount}',
    },
    'margin': {
      AppLanguage.english: 'Margin {amount}',
      AppLanguage.amharic: 'ልዩነት {amount}',
    },
    'stockOut': {AppLanguage.english: 'Out', AppLanguage.amharic: 'አልቋል'},
    'stockLow': {AppLanguage.english: 'Low', AppLanguage.amharic: 'ዝቅተኛ'},
    'stockGood': {AppLanguage.english: 'Good', AppLanguage.amharic: 'ጥሩ'},
    'salesPos': {
      AppLanguage.english: 'Sales POS',
      AppLanguage.amharic: 'የሽያጭ POS',
    },
    'ownerPos': {
      AppLanguage.english: 'Owner POS',
      AppLanguage.amharic: 'የባለቤት POS',
    },
    'searchProductShort': {
      AppLanguage.english: 'Search products',
      AppLanguage.amharic: 'እቃ ፈልግ',
    },
    'products': {
      AppLanguage.english: 'Products',
      AppLanguage.amharic: 'እቃዎች',
    },
    'cartTotal': {
      AppLanguage.english: 'Cart total',
      AppLanguage.amharic: 'የጋሪ ድምር',
    },
    'estimatedProfit': {
      AppLanguage.english: 'Est. profit',
      AppLanguage.amharic: 'ተገመተ ትርፍ',
    },
    'noProductsAvailable': {
      AppLanguage.english: 'No products available',
      AppLanguage.amharic: 'የሚሸጥ እቃ የለም',
    },
    'noProductMatch': {
      AppLanguage.english: 'No products matched',
      AppLanguage.amharic: 'የተመሳሰለ እቃ አልተገኘም',
    },
    'addInventoryBeforePos': {
      AppLanguage.english: 'Add stock before opening POS.',
      AppLanguage.amharic: 'POS ከመክፈት በፊት እቃ ያስገቡ።',
    },
    'tryAnotherSearch': {
      AppLanguage.english: 'Try another search word.',
      AppLanguage.amharic: 'ሌላ የፍለጋ ቃል ይሞክሩ።',
    },
    'addToCart': {
      AppLanguage.english: 'Add to cart',
      AppLanguage.amharic: 'ወደ ጋሪ ጨምር',
    },
    'cart': {AppLanguage.english: 'Cart', AppLanguage.amharic: 'ጋሪ'},
    'viewCart': {
      AppLanguage.english: 'View cart',
      AppLanguage.amharic: 'ጋሪውን ይዩ',
    },
    'itemCountShort': {
      AppLanguage.english: '{count} item(s)',
      AppLanguage.amharic: '{count} እቃ',
    },
    'setPricesBeforeCheckout': {
      AppLanguage.english: 'Add products and set prices before checkout.',
      AppLanguage.amharic: 'ከመውጫው በፊት እቃ ጨምሩ እና ዋጋ ያስቀምጡ።',
    },
    'subtotal': {
      AppLanguage.english: 'Subtotal',
      AppLanguage.amharic: 'ንዑስ ድምር',
    },
    'checkout': {AppLanguage.english: 'Checkout', AppLanguage.amharic: 'ጨርስ'},
    'setPriceFor': {
      AppLanguage.english: 'Set price for {name}',
      AppLanguage.amharic: 'ለ{name} ዋጋ አስቀምጥ',
    },
    'sellingPrice': {
      AppLanguage.english: 'Selling price',
      AppLanguage.amharic: 'የሽያጭ ዋጋ',
    },
    'update': {AppLanguage.english: 'Update', AppLanguage.amharic: 'አዘምን'},
    'saleDoneFor': {
      AppLanguage.english: 'Sale done for {amount}.',
      AppLanguage.amharic: 'ሽያጩ {amount} ተጠናቋል።',
    },
    'noMoreStock': {
      AppLanguage.english: '{name} has no more stock.',
      AppLanguage.amharic: '{name} ተጨማሪ ክምችት የለውም።',
    },
    'onlyUnitsLeft': {
      AppLanguage.english: '{name} has only {count} left.',
      AppLanguage.amharic: '{name} {count} ብቻ ቀርቶታል።',
    },
    'addFastMoney': {
      AppLanguage.english: 'Add fast money',
      AppLanguage.amharic: 'ፈጣን ገቢ ጨምር',
    },
    'productOrService': {
      AppLanguage.english: 'Product or service',
      AppLanguage.amharic: 'እቃ ወይም አገልግሎት',
    },
    'productOrServiceRequired': {
      AppLanguage.english: 'Enter a product or service name.',
      AppLanguage.amharic: 'የእቃ ወይም የአገልግሎት ስም ያስገቡ።',
    },
    'priceIncome': {
      AppLanguage.english: 'Price (income)',
      AppLanguage.amharic: 'ዋጋ (ገቢ)',
    },
    'purchaseCost': {
      AppLanguage.english: 'Purchase cost',
      AppLanguage.amharic: 'የግዢ ወጪ',
    },
    'autoProfit': {
      AppLanguage.english: 'Profit',
      AppLanguage.amharic: 'ትርፍ',
    },
    'saveFastMoney': {
      AppLanguage.english: 'Save fast money',
      AppLanguage.amharic: 'ፈጣን ገቢን አስቀምጥ',
    },
    'fastMoneySaved': {
      AppLanguage.english: 'Fast money saved.',
      AppLanguage.amharic: 'ፈጣን ገቢው ተመዝግቧል።',
    },
    'fastMoneyEntries': {
      AppLanguage.english: 'Fast money entries',
      AppLanguage.amharic: 'የፈጣን ገቢ መዝገቦች',
    },
    'noFastMoneyYet': {
      AppLanguage.english: 'No fast money yet',
      AppLanguage.amharic: 'እስካሁን ፈጣን ገቢ የለም',
    },
    'fastMoneyHelp': {
      AppLanguage.english:
          'Use this for quick one-line product or service income.',
      AppLanguage.amharic: 'ይህን ለፈጣን አንድ-መስመር የእቃ ወይም የአገልግሎት ገቢ ይጠቀሙ።',
    },
    'addExpense': {
      AppLanguage.english: 'Add expense',
      AppLanguage.amharic: 'ወጪ ጨምር',
    },
    'type': {AppLanguage.english: 'Type', AppLanguage.amharic: 'አይነት'},
    'amount': {AppLanguage.english: 'Amount', AppLanguage.amharic: 'መጠን'},
    'descriptionRequired': {
      AppLanguage.english: 'Description is required.',
      AppLanguage.amharic: 'መግለጫ ያስፈልጋል።',
    },
    'validAmount': {
      AppLanguage.english: 'Enter a valid amount.',
      AppLanguage.amharic: 'ትክክለኛ መጠን ያስገቡ።',
    },
    'saveExpense': {
      AppLanguage.english: 'Save expense',
      AppLanguage.amharic: 'ወጪ አስቀምጥ',
    },
    'deleteExpense': {
      AppLanguage.english: 'Delete expense',
      AppLanguage.amharic: 'ወጪ ሰርዝ',
    },
    'deleteExpenseMessage': {
      AppLanguage.english: 'Delete "{name}"?',
      AppLanguage.amharic: '"{name}" ልትሰርዝ?',
    },
    'operating': {
      AppLanguage.english: 'Running cost',
      AppLanguage.amharic: 'የስራ ወጪ',
    },
    'withdrawals': {
      AppLanguage.english: 'Take-outs',
      AppLanguage.amharic: 'የተወሰደ ገንዘብ',
    },
    'noExpenseItemsYet': {
      AppLanguage.english: 'No expenses yet',
      AppLanguage.amharic: 'ገና ወጪ የለም',
    },
    'expenseHelp': {
      AppLanguage.english: 'Track shop costs and owner take-outs here.',
      AppLanguage.amharic: 'የሱቅ ወጪ እና የባለቤት የተወሰደ ገንዘብ እዚህ ይመዝግቡ።',
    },
    'addedBy': {
      AppLanguage.english: 'Added by {name}',
      AppLanguage.amharic: 'የጨመረው {name}',
    },
    'expenseFab': {AppLanguage.english: 'Expense', AppLanguage.amharic: 'ወጪ'},
    'createStaffAccount': {
      AppLanguage.english: 'Create staff account',
      AppLanguage.amharic: 'የሰራተኛ መለያ ፍጠር',
    },
    'role': {AppLanguage.english: 'Role', AppLanguage.amharic: 'ሚና'},
    'temporaryPassword': {
      AppLanguage.english: 'Temporary password',
      AppLanguage.amharic: 'ጊዜያዊ የይለፍ ቃል',
    },
    'createAccount': {
      AppLanguage.english: 'Create account',
      AppLanguage.amharic: 'መለያ ፍጠር',
    },
    'staffCreated': {
      AppLanguage.english: 'Staff account created.',
      AppLanguage.amharic: 'የሰራተኛ መለያ ተፈጥሯል።',
    },
    'activeUsers': {
      AppLanguage.english: 'Active users',
      AppLanguage.amharic: 'ንቁ ተጠቃሚዎች',
    },
    'owners': {AppLanguage.english: 'Owners', AppLanguage.amharic: 'ባለቤቶች'},
    'staffNote': {
      AppLanguage.english:
          'You can turn accounts on or off here. Full deletion is still a backend job.',
      AppLanguage.amharic:
          'መለያዎችን እዚህ ማብራት ወይም ማጥፋት ይችላሉ። ሙሉ ስረዛ ከbackend ይፈልጋል።',
    },
    'noStaffYet': {
      AppLanguage.english: 'No staff accounts yet',
      AppLanguage.amharic: 'ገና የሰራተኛ መለያ የለም',
    },
    'staffHelp': {
      AppLanguage.english: 'Create a clerk or another owner to get started.',
      AppLanguage.amharic: 'ለመጀመር ካሽየር ወይም ሌላ ባለቤት ይፍጠሩ።',
    },
    'active': {AppLanguage.english: 'Active', AppLanguage.amharic: 'ንቁ'},
    'disabled': {AppLanguage.english: 'Disabled', AppLanguage.amharic: 'የተዘጋ'},
    'you': {AppLanguage.english: 'You', AppLanguage.amharic: 'እርስዎ'},
    'staffFab': {AppLanguage.english: 'Staff', AppLanguage.amharic: 'ሰራተኞች'},
    'createProductsFirst': {
      AppLanguage.english: 'Add products before you record restocks.',
      AppLanguage.amharic: 'እቃ መሙላት ከመመዝገብ በፊት እቃ ያስገቡ።',
    },
    'addPurchaseItem': {
      AppLanguage.english: 'Add purchase item',
      AppLanguage.amharic: 'የግዢ እቃ ጨምር',
    },
    'searchProductsToRestock': {
      AppLanguage.english: 'Search products to restock',
      AppLanguage.amharic: 'ለመሙላት እቃ ፈልግ',
    },
    'pickProduct': {
      AppLanguage.english: 'Pick a product',
      AppLanguage.amharic: 'እቃ ይምረጡ',
    },
    'noProductsInCategory': {
      AppLanguage.english: 'Try another category or search word.',
      AppLanguage.amharic: 'ሌላ ምድብ ወይም የፍለጋ ቃል ይሞክሩ።',
    },
    'product': {AppLanguage.english: 'Product', AppLanguage.amharic: 'እቃ'},
    'quantity': {AppLanguage.english: 'Quantity', AppLanguage.amharic: 'ብዛት'},
    'validQuantity': {
      AppLanguage.english: 'Enter a valid quantity.',
      AppLanguage.amharic: 'ትክክለኛ ብዛት ያስገቡ።',
    },
    'unitCost': {
      AppLanguage.english: 'Unit cost',
      AppLanguage.amharic: 'የአንዱ ዋጋ',
    },
    'validUnitCost': {
      AppLanguage.english: 'Enter a valid unit cost.',
      AppLanguage.amharic: 'ትክክለኛ የአንዱ ዋጋ ያስገቡ።',
    },
    'addItem': {AppLanguage.english: 'Add item', AppLanguage.amharic: 'እቃ ጨምር'},
    'addOneItemFirst': {
      AppLanguage.english: 'Add at least one item first.',
      AppLanguage.amharic: 'ቢያንስ አንድ እቃ መጀመሪያ ያክሉ።',
    },
    'restockRecorded': {
      AppLanguage.english: 'Restock saved.',
      AppLanguage.amharic: 'መሙላቱ ተመዝግቧል።',
    },
    'newPurchase': {
      AppLanguage.english: 'New purchase',
      AppLanguage.amharic: 'አዲስ ግዢ',
    },
    'supplierOrSource': {
      AppLanguage.english: 'Supplier or source',
      AppLanguage.amharic: 'አቅራቢ ወይም ምንጭ',
    },
    'noteOrInvoice': {
      AppLanguage.english: 'Note or invoice info',
      AppLanguage.amharic: 'ማስታወሻ ወይም የደረሰኝ መረጃ',
    },
    'record': {AppLanguage.english: 'Record', AppLanguage.amharic: 'መዝግብ'},
    'currentPurchaseTotal': {
      AppLanguage.english: 'Current purchase total',
      AppLanguage.amharic: 'የአሁኑ ግዢ ድምር',
    },
    'noItemsInPurchaseYet': {
      AppLanguage.english: 'No items yet',
      AppLanguage.amharic: 'ገና እቃ የለም',
    },
    'purchaseHelp': {
      AppLanguage.english: 'Add products with quantity and unit cost.',
      AppLanguage.amharic: 'እቃዎችን በብዛትና በየአንዱ ዋጋ ያክሉ።',
    },
    'recentPurchases': {
      AppLanguage.english: 'Recent purchases',
      AppLanguage.amharic: 'የቅርብ ግዢዎች',
    },
    'noPurchaseHistoryYet': {
      AppLanguage.english: 'No purchase history yet',
      AppLanguage.amharic: 'ገና የግዢ ታሪክ የለም',
    },
    'purchaseHistoryHelp': {
      AppLanguage.english: 'Saved restocks will show here with cost details.',
      AppLanguage.amharic: 'የተመዘገቡ መሙላቶች ከወጪ ዝርዝር ጋር እዚህ ይታያሉ።',
    },
    'each': {AppLanguage.english: 'each', AppLanguage.amharic: 'እያንዳንዱ'},
    'services': {
      AppLanguage.english: 'Services',
      AppLanguage.amharic: 'አገልግሎቶች',
    },
    'serviceShortHint': {
      AppLanguage.english: 'Track repair jobs and income',
      AppLanguage.amharic: 'የጥገና ስራዎችን እና ገቢያቸውን ይከታተሉ',
    },
    'allStatuses': {
      AppLanguage.english: 'All statuses',
      AppLanguage.amharic: 'ሁሉም ሁኔታዎች',
    },
    'serviceType': {
      AppLanguage.english: 'Service type',
      AppLanguage.amharic: 'የአገልግሎት አይነት',
    },
    'serviceTypeRequired': {
      AppLanguage.english: 'Enter the service type.',
      AppLanguage.amharic: 'የአገልግሎቱን አይነት ያስገቡ።',
    },
    'customerName': {
      AppLanguage.english: 'Customer name',
      AppLanguage.amharic: 'የደንበኛ ስም',
    },
    'customerNameRequired': {
      AppLanguage.english: 'Enter the customer name.',
      AppLanguage.amharic: 'የደንበኛውን ስም ያስገቡ።',
    },
    'customerPhone': {
      AppLanguage.english: 'Customer phone',
      AppLanguage.amharic: 'የደንበኛ ስልክ',
    },
    'customerPhoneRequired': {
      AppLanguage.english: 'Enter the customer phone.',
      AppLanguage.amharic: 'የደንበኛውን ስልክ ያስገቡ።',
    },
    'serviceStatus': {
      AppLanguage.english: 'Service status',
      AppLanguage.amharic: 'የአገልግሎት ሁኔታ',
    },
    'serviceCharge': {
      AppLanguage.english: 'Service charge',
      AppLanguage.amharic: 'የአገልግሎት ክፍያ',
    },
    'serviceIncome': {
      AppLanguage.english: 'Service income',
      AppLanguage.amharic: 'የአገልግሎት ገቢ',
    },
    'maintenanceCost': {
      AppLanguage.english: 'Maintenance cost',
      AppLanguage.amharic: 'የጥገና ወጪ',
    },
    'noCost': {
      AppLanguage.english: 'No cost',
      AppLanguage.amharic: 'ወጪ የለም',
    },
    'cashCost': {
      AppLanguage.english: 'Cash cost',
      AppLanguage.amharic: 'የገንዘብ ወጪ',
    },
    'sparePartFromStock': {
      AppLanguage.english: 'Spare part from stock',
      AppLanguage.amharic: 'ከክምችት መለዋወጫ',
    },
    'quantityUsed': {
      AppLanguage.english: 'Quantity used',
      AppLanguage.amharic: 'የተጠቀሰ ብዛት',
    },
    'serviceNote': {
      AppLanguage.english: 'Service note',
      AppLanguage.amharic: 'የአገልግሎት ማስታወሻ',
    },
    'addServiceJob': {
      AppLanguage.english: 'Add service job',
      AppLanguage.amharic: 'የአገልግሎት ስራ ጨምር',
    },
    'saveServiceJob': {
      AppLanguage.english: 'Save service',
      AppLanguage.amharic: 'አገልግሎቱን አስቀምጥ',
    },
    'serviceSaved': {
      AppLanguage.english: 'Service saved.',
      AppLanguage.amharic: 'አገልግሎቱ ተመዝግቧል።',
    },
    'pendingServices': {
      AppLanguage.english: 'Pending services',
      AppLanguage.amharic: 'በመጠባበቅ ላይ ያሉ አገልግሎቶች',
    },
    'paidIncome': {
      AppLanguage.english: 'Paid income',
      AppLanguage.amharic: 'የተከፈለ ገቢ',
    },
    'unpaidIncome': {
      AppLanguage.english: 'Unpaid income',
      AppLanguage.amharic: 'ያልተከፈለ ገቢ',
    },
    'noServicesYet': {
      AppLanguage.english: 'No services yet',
      AppLanguage.amharic: 'እስካሁን አገልግሎት የለም',
    },
    'serviceHelp': {
      AppLanguage.english:
          'Add a repair or maintenance job and track its status.',
      AppLanguage.amharic: 'የጥገና ወይም የአገልግሎት ስራ ጨምሩ እና ሁኔታውን ይከታተሉ።',
    },
    'noSparePartsAvailable': {
      AppLanguage.english: 'No spare parts available',
      AppLanguage.amharic: 'የሚጠቀሙ መለዋወጫዎች የሉም',
    },
    'addInventoryBeforeServiceParts': {
      AppLanguage.english: 'Add stock first before using spare parts.',
      AppLanguage.amharic: 'መለዋወጫ ከመጠቀምዎ በፊት ክምችት ያስገቡ።',
    },
    'searchSpareParts': {
      AppLanguage.english: 'Search spare parts',
      AppLanguage.amharic: 'መለዋወጫ ይፈልጉ',
    },
    'chooseSparePart': {
      AppLanguage.english: 'Choose spare part',
      AppLanguage.amharic: 'መለዋወጫ ይምረጡ',
    },
  };

  String t(String key, [Map<String, String> params = const {}]) {
    var template =
        _strings[key]?[language] ?? _strings[key]?[AppLanguage.english] ?? key;

    params.forEach((name, value) {
      template = template.replaceAll('{$name}', value);
    });

    return template;
  }

  String roleLabel(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return language == AppLanguage.amharic ? 'ባለቤት' : 'Owner';
      case UserRole.clerk:
        return language == AppLanguage.amharic ? 'ካሽየር' : 'Clerk';
    }
  }

  String expenseKindLabel(ExpenseKind kind) {
    switch (kind) {
      case ExpenseKind.operating:
        return t('operating');
      case ExpenseKind.withdrawal:
        return t('withdrawals');
    }
  }

  String serviceStatusLabel(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.pending:
        return language == AppLanguage.amharic
            ? 'በመጠባበቅ ላይ'
            : 'Pending';
      case ServiceStatus.completedUnpaid:
        return language == AppLanguage.amharic
            ? 'ተጠናቋል - ያልተከፈለ'
            : 'Completed - unpaid';
      case ServiceStatus.completedPaid:
        return language == AppLanguage.amharic
            ? 'ተጠናቋል - ተከፍሏል'
            : 'Completed - paid';
    }
  }

  String languageLabel(AppLanguage value) {
    return value == AppLanguage.english ? t('english') : t('amharic');
  }
}

extension AppLanguageContext on BuildContext {
  AppLocalizer get strings => watch<AppLanguageProvider>().strings;
  AppLocalizer get readStrings => read<AppLanguageProvider>().strings;
  AppLanguageProvider get languageController => read<AppLanguageProvider>();
}
