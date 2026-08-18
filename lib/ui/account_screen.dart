import 'package:flutter/material.dart';
import '../cloud/cloud_account_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override State<AccountScreen> createState()=>_AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _cloud=CloudAccountService.instance;
  final _email=TextEditingController();
  final _password=TextEditingController();
  bool _busy=false, _createMode=false, _hidePassword=true;
  @override void dispose(){_email.dispose();_password.dispose();super.dispose();}

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('MORSEBOUND ACCOUNT')),
    body:ValueListenableBuilder<CloudAccountState>(
      valueListenable:_cloud.state,
      builder:(context,state,_)=>SingleChildScrollView(
        padding:EdgeInsets.fromLTRB(18,18,18,24+MediaQuery.viewInsetsOf(context).bottom),
        child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:620),child:state.available?(state.signedIn?_signedIn(state):_signedOut(state)):_notConfigured(state))),
      ),
    ),
  );

  Widget _notConfigured(CloudAccountState s)=>Card(child:Padding(padding:const EdgeInsets.all(22),child:Column(children:[
    const Icon(Icons.cloud_off_rounded,size:54,color:Color(0xFFFFD166)),const SizedBox(height:14),
    const Text('CLOUD ACCOUNT SETUP PENDING',textAlign:TextAlign.center,style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:10),
    const Text('Morsebound is still fully usable offline. Cloud accounts activate after the Firebase project is connected for this release.',textAlign:TextAlign.center),
    if(s.error!=null)...[const SizedBox(height:12),Text(s.error!,textAlign:TextAlign.center,style:const TextStyle(color:Color(0xFFFFB4AB),fontSize:11))]
  ])));

  Widget _signedOut(CloudAccountState s)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    const Text('YOUR MORSEBOUND ACCOUNT',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:6),
    const Text('Sign in to keep mastery, retention, career progress, streaks, and settings synchronized across devices.',style:TextStyle(color:Color(0xFFA9BBC1))),const SizedBox(height:18),
    Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      TextField(controller:_email,enabled:!_busy,keyboardType:TextInputType.emailAddress,autofillHints:const[AutofillHints.email],decoration:const InputDecoration(labelText:'Email',prefixIcon:Icon(Icons.email_outlined))),const SizedBox(height:12),
      TextField(controller:_password,enabled:!_busy,obscureText:_hidePassword,autofillHints:const[AutofillHints.password],onSubmitted:(_)=>_submit(),decoration:InputDecoration(labelText:'Password',prefixIcon:const Icon(Icons.lock_outline),suffixIcon:IconButton(onPressed:()=>setState(()=>_hidePassword=!_hidePassword),icon:Icon(_hidePassword?Icons.visibility_outlined:Icons.visibility_off_outlined)))),
      if(s.error!=null)...[const SizedBox(height:12),Text(s.error!,style:const TextStyle(color:Color(0xFFFFB4AB)))],const SizedBox(height:16),
      FilledButton.icon(onPressed:_busy?null:_submit,icon:_busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):Icon(_createMode?Icons.person_add_alt_1_rounded:Icons.login_rounded),label:Text(_createMode?'CREATE ACCOUNT':'SIGN IN')),
      const SizedBox(height:10),
      Row(children:const [Expanded(child:Divider()),Padding(padding:EdgeInsets.symmetric(horizontal:12),child:Text('OR',style:TextStyle(color:Color(0xFF82969D),fontSize:11,fontWeight:FontWeight.w800))),Expanded(child:Divider())]),
      const SizedBox(height:10),
      OutlinedButton.icon(onPressed:_busy?null:_signInWithGoogle,icon:const Icon(Icons.g_mobiledata_rounded,size:28),label:const Text('CONTINUE WITH GOOGLE')),
      const SizedBox(height:8),TextButton(onPressed:_busy?null:()=>setState(()=>_createMode=!_createMode),child:Text(_createMode?'I ALREADY HAVE AN ACCOUNT':'CREATE A NEW ACCOUNT')),
      TextButton(onPressed:_busy?null:_resetPassword,child:const Text('FORGOT PASSWORD?')),
    ]))),const SizedBox(height:12),
    const Text('Offline-first: Morsebound keeps local progress even when you are signed out or temporarily offline.',textAlign:TextAlign.center,style:TextStyle(color:Color(0xFF82969D),fontSize:12)),
  ]);

  Widget _signedIn(CloudAccountState s)=>Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[
      const Icon(Icons.cloud_done_rounded,size:58,color:Color(0xFF8FFFEA)),const SizedBox(height:12),const Text('CLOUD SYNC ACTIVE',style:TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:6),Text(s.user?.email??'Morsebound user'),const SizedBox(height:8),
      Text(s.syncing?'Synchronizing progress...':s.lastSync==null?'Ready to synchronize':'Last sync: ${_formatSync(s.lastSync!)}',style:const TextStyle(color:Color(0xFFA9BBC1),fontSize:12)),
      if(s.error!=null)...[const SizedBox(height:10),Text(s.error!,textAlign:TextAlign.center,style:const TextStyle(color:Color(0xFFFFB4AB)))]
    ]))),const SizedBox(height:12),
    FilledButton.icon(onPressed:s.syncing?null:()=>_cloud.syncNow(),icon:const Icon(Icons.sync_rounded),label:const Text('SYNC NOW')),const SizedBox(height:8),
    OutlinedButton.icon(onPressed:_busy?null:_signOut,icon:const Icon(Icons.logout_rounded),label:const Text('SIGN OUT')),const SizedBox(height:18),
    TextButton.icon(onPressed:_busy?null:_deleteAccount,icon:const Icon(Icons.delete_forever_outlined),label:const Text('DELETE CLOUD ACCOUNT')),
  ]);

  Future<void> _submit() async {final e=_email.text.trim(),p=_password.text;if(e.isEmpty||p.isEmpty){_show('Enter both email and password.');return;}setState(()=>_busy=true);try{if(_createMode){await _cloud.createAccount(email:e,password:p);}else{await _cloud.signIn(email:e,password:p);}}catch(_){ }finally{if(mounted)setState(()=>_busy=false);}}
  Future<void> _signInWithGoogle() async {
    setState(() => _busy = true);
    try {
      await _cloud.signInWithGoogle();
    } catch (_) {
      // Friendly error is exposed by CloudAccountState.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {final e=_email.text.trim();if(e.isEmpty){_show('Enter your email first.');return;}setState(()=>_busy=true);try{await _cloud.sendPasswordReset(e);_show('Password reset email sent.');}catch(_){ }finally{if(mounted)setState(()=>_busy=false);}}
  Future<void> _signOut() async {setState(()=>_busy=true);try{await _cloud.signOut();}finally{if(mounted)setState(()=>_busy=false);}}
  Future<void> _deleteAccount() async {final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(title:const Text('Delete cloud account?'),content:const Text('This deletes the online Morsebound progress and the cloud account. Local progress on this device is kept unless you separately reset it.'),actions:[TextButton(onPressed:()=>Navigator.of(c).pop(false),child:const Text('CANCEL')),FilledButton(onPressed:()=>Navigator.of(c).pop(true),child:const Text('DELETE'))]))??false;if(!ok)return;setState(()=>_busy=true);try{await _cloud.deleteCloudAccount();}catch(_){ }finally{if(mounted)setState(()=>_busy=false);}}
  void _show(String m){if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(m)));}
  String _formatSync(DateTime t){final l=t.toLocal();return '${l.month}/${l.day} ${l.hour.toString().padLeft(2,'0')}:${l.minute.toString().padLeft(2,'0')}';}
}
